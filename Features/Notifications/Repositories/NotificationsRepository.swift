import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol NotificationsRepository {
    func loadNotifications() async throws -> [AppNotification]
    func notificationUpdates() -> AsyncThrowingStream<[AppNotification], Error>
    func unreadCount() async throws -> Int
    func markAsRead(_ notification: AppNotification) async throws
    func resolveInvitation(_ notification: AppNotification, accept: Bool) async throws
}

struct FirestoreNotificationsRepository: NotificationsRepository {
    private let db = Firestore.firestore()
    private let itemPaths = [
        "notifications/connectionRequests/items",
        "notifications/assignments/items",
        "notifications/all/items",
        "notifications/personal/items"
    ]

    func loadNotifications() async throws -> [AppNotification] {
        guard let user = Auth.auth().currentUser else { return [] }

        async let requestSnapshot = db.collection(itemPaths[0])
            .whereField("recipientId", isEqualTo: user.uid)
            .getDocuments()
        async let assignmentSnapshot = db.collection(itemPaths[1])
            .whereField("recipientId", isEqualTo: user.uid)
            .getDocuments()
        async let allSnapshot = db.collection(itemPaths[2])
            .getDocuments()
        async let personalSnapshot = db.collection(itemPaths[3])
            .whereField("recipientId", isEqualTo: user.uid)
            .getDocuments()
        async let personalEmailSnapshot = db.collection(itemPaths[3])
            .whereField("recipientEmail", isEqualTo: user.email?.lowercased() ?? "")
            .getDocuments()

        let documents = try await requestSnapshot.documents
            + assignmentSnapshot.documents
            + allSnapshot.documents
            + personalSnapshot.documents
            + personalEmailSnapshot.documents
        return Dictionary(grouping: documents, by: \.reference.path).compactMap(\.value.first)
            .map(mapNotification)
            .sorted { $0.createdAt > $1.createdAt }
    }

    func unreadCount() async throws -> Int {
        try await loadNotifications().filter { !$0.isRead }.count
    }

    func notificationUpdates() -> AsyncThrowingStream<[AppNotification], Error> {
        AsyncThrowingStream { continuation in
            guard let user = Auth.auth().currentUser else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let state = NotificationListenerState(map: mapNotification, continuation: continuation)
            let requestListener = db.collection(itemPaths[0])
                .whereField("recipientId", isEqualTo: user.uid)
                .addSnapshotListener { snapshot, error in
                    state.update(index: 0, snapshot: snapshot, error: error)
                }
            let assignmentListener = db.collection(itemPaths[1])
                .whereField("recipientId", isEqualTo: user.uid)
                .addSnapshotListener { snapshot, error in
                    state.update(index: 1, snapshot: snapshot, error: error)
                }
            let allListener = db.collection(itemPaths[2])
                .addSnapshotListener { snapshot, error in
                    state.update(index: 2, snapshot: snapshot, error: error)
                }
            let personalListener = db.collection(itemPaths[3])
                .whereField("recipientId", isEqualTo: user.uid)
                .addSnapshotListener { snapshot, error in
                    state.update(index: 3, snapshot: snapshot, error: error)
                }
            let personalEmailListener = db.collection(itemPaths[3])
                .whereField("recipientEmail", isEqualTo: user.email?.lowercased() ?? "")
                .addSnapshotListener { snapshot, error in
                    state.update(index: 4, snapshot: snapshot, error: error)
                }

            continuation.onTermination = { _ in
                requestListener.remove()
                assignmentListener.remove()
                allListener.remove()
                personalListener.remove()
                personalEmailListener.remove()
            }
        }
    }

    func markAsRead(_ notification: AppNotification) async throws {
        if notification.sourcePath.contains("/all/"), let userID = Auth.auth().currentUser?.uid {
            try await db.document(notification.sourcePath).setData([
                "readBy": FieldValue.arrayUnion([userID])
            ], merge: true)
        } else {
            try await db.document(notification.sourcePath).setData(["isRead": true], merge: true)
        }
    }

    func resolveInvitation(_ notification: AppNotification, accept: Bool) async throws {
        guard let teacher = Auth.auth().currentUser,
              let requestID = notification.requestID,
              let studentID = notification.senderID,
              notification.isPendingInvitation,
              notification.recipientID == teacher.uid ||
                notification.recipientEmail?.lowercased() == teacher.email?.lowercased() else {
            return
        }

        let status = accept ? AppNotificationStatus.accepted.rawValue : AppNotificationStatus.declined.rawValue
        let timestamp = FieldValue.serverTimestamp()
        let batch = db.batch()
        let notificationReference = db.document(notification.sourcePath)

        let decisionPayload: [String: Any] = [
            "status": status,
            "decision": status,
            "decidedBy": teacher.uid,
            "recipientId": teacher.uid,
            "teacherId": teacher.uid,
            "resolvedAt": timestamp,
            "updatedAt": timestamp,
            "isRead": true
        ]
        batch.setData(decisionPayload, forDocument: notificationReference, merge: true)

        if accept {
            batch.setData([
                "teacherIds": FieldValue.arrayUnion([teacher.uid]),
                "updatedAt": timestamp
            ], forDocument: db.collection("students").document(studentID), merge: true)
            batch.setData([
                "studentIds": FieldValue.arrayUnion([studentID]),
                "updatedAt": timestamp
            ], forDocument: db.collection("teachers").document(teacher.uid), merge: true)
        }

        let resultNotification = db.collection("notifications/personal/items").document()
        batch.setData([
            "type": "personal",
            "updatedAt": timestamp
        ], forDocument: db.collection("notifications").document("personal"), merge: true)
        batch.setData([
            "senderId": teacher.uid,
            "senderName": teacher.displayName ?? notification.recipientName ?? "Репетитор",
            "senderEmail": teacher.email ?? notification.recipientEmail ?? "",
            "recipientId": studentID,
            "recipientName": notification.senderName ?? "Ученик",
            "recipientEmail": notification.senderEmail ?? "",
            "requestId": requestID,
            "title": accept ? "Репетитор добавлен" : "Запрос отклонён",
            "message": accept
                ? "\(teacher.displayName ?? notification.recipientName ?? "Репетитор") принял ваш запрос."
                : "\(teacher.displayName ?? notification.recipientName ?? "Репетитор") отклонил ваш запрос.",
            "type": "system",
            "status": status,
            "decision": status,
            "isRead": false,
            "createdAt": timestamp,
            "updatedAt": timestamp
        ], forDocument: resultNotification)

        try await batch.commit()
    }

    private func mapNotification(_ document: QueryDocumentSnapshot) -> AppNotification {
        let data = document.data()
        let timestamp = data["createdAt"] as? Timestamp
        let typeRaw = data["type"] as? String
        let type = AppNotificationType(rawValue: typeRaw ?? "") ?? inferredType(for: document.reference.path)
        let isBroadcast = document.reference.path.contains("/all/")
        let readBy = data["readBy"] as? [String] ?? []
        let isRead = isBroadcast
            ? readBy.contains(Auth.auth().currentUser?.uid ?? "")
            : data["isRead"] as? Bool ?? false

        return AppNotification(
            id: document.documentID,
            title: data["title"] as? String ?? "Уведомление",
            message: data["message"] as? String ?? "",
            type: type,
            createdAt: timestamp?.dateValue() ?? Date(),
            isRead: isRead,
            assignmentID: data["assignmentId"] as? String,
            requestID: data["requestId"] as? String,
            senderID: data["senderId"] as? String,
            senderName: data["senderName"] as? String,
            senderEmail: data["senderEmail"] as? String,
            recipientID: data["recipientId"] as? String,
            recipientName: data["recipientName"] as? String,
            recipientEmail: data["recipientEmail"] as? String,
            status: AppNotificationStatus(rawValue: data["status"] as? String ?? "") ?? .informational,
            sourcePath: document.reference.path
        )
    }

    private func inferredType(for path: String) -> AppNotificationType {
        if path.contains("/connectionRequests/") { return .invitation }
        if path.contains("/assignments/") { return .assignment }
        if path.contains("/all/") { return .broadcast }
        if path.contains("/personal/") { return .personal }
        return .system
    }
}

private final class NotificationListenerState: @unchecked Sendable {
    private let lock = NSLock()
    private var documentsBySource = Array(repeating: [QueryDocumentSnapshot](), count: 5)
    private let map: (QueryDocumentSnapshot) -> AppNotification
    private let continuation: AsyncThrowingStream<[AppNotification], Error>.Continuation

    init(
        map: @escaping (QueryDocumentSnapshot) -> AppNotification,
        continuation: AsyncThrowingStream<[AppNotification], Error>.Continuation
    ) {
        self.map = map
        self.continuation = continuation
    }

    func update(index: Int, snapshot: QuerySnapshot?, error: Error?) {
        lock.lock()
        documentsBySource[index] = snapshot?.documents ?? []
        let documents = documentsBySource.flatMap { $0 }
        lock.unlock()

        #if DEBUG
        if let error {
            print("[Notifications] listener source \(index) failed: \(error.localizedDescription)")
        }
        #endif

        let notifications = Dictionary(grouping: documents, by: \.reference.path)
            .compactMap(\.value.first)
            .map(map)
            .sorted { $0.createdAt > $1.createdAt }
        continuation.yield(notifications)
    }
}
