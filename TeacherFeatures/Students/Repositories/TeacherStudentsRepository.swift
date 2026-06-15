import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol TeacherStudentsRepository {
    func loadStudents() async throws -> [TeacherLocalStudent]
    func addStudent(publicID: String, className: String, note: String) async throws
    func saveStudent(_ student: TeacherLocalStudent) async throws
    func deleteStudent(id: String) async throws
    func inviteStudent(email: String, message: String) async throws
}

struct DefaultTeacherStudentsRepository: TeacherStudentsRepository {
    private let localDatabase: LocalDatabase
    private let database = Firestore.firestore()

    init(localDatabase: LocalDatabase) {
        self.localDatabase = localDatabase
    }

    func loadStudents() async throws -> [TeacherLocalStudent] {
        let localStudents = try await localDatabase.loadRecords(TeacherLocalStudent.self, entity: localEntity)
        guard let teacherID = Auth.auth().currentUser?.uid else {
            return sorted(localStudents)
        }

        let teacherDocument = try await database.collection("teachers").document(teacherID).getDocument()
        let connectedIDs = teacherDocument.data()?["studentIds"] as? [String] ?? []
        var studentsByID = Dictionary(uniqueKeysWithValues: localStudents.map { ($0.id, $0) })

        for studentID in connectedIDs where studentsByID[studentID] == nil {
            let studentDocument = try await database.collection("students").document(studentID).getDocument()
            guard let data = studentDocument.data() else { continue }
            let now = Date()
            let student = TeacherLocalStudent(
                id: studentID,
                publicID: data["publicToken"] as? String ?? AppUserIDGenerator.sixDigitID(from: studentID),
                name: data["name"] as? String ?? "Ученик",
                className: "",
                note: "",
                createdAt: now,
                updatedAt: now
            )
            try await saveStudent(student)
            studentsByID[studentID] = student
        }

        return sorted(Array(studentsByID.values))
    }

    func saveStudent(_ student: TeacherLocalStudent) async throws {
        try await localDatabase.saveRecord(
            student,
            entity: localEntity,
            id: student.id,
            syncStatus: .synced
        )
    }

    func addStudent(publicID: String, className: String, note: String) async throws {
        let normalizedID = publicID.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = try await database
            .collection("students")
            .whereField("publicToken", isEqualTo: normalizedID)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw TeacherStudentsRepositoryError.studentNotFound
        }

        let data = document.data()
        let now = Date()
        let student = TeacherLocalStudent(
            id: document.documentID,
            publicID: data["publicToken"] as? String ?? normalizedID,
            name: data["name"] as? String ?? "Ученик",
            className: className.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: now,
            updatedAt: now
        )
        try await saveStudent(student)
    }

    func deleteStudent(id: String) async throws {
        try await localDatabase.deleteRecord(entity: localEntity, id: id, syncStatus: .synced)
    }

    func inviteStudent(email: String, message: String) async throws {
        guard let teacher = Auth.auth().currentUser else {
            throw TeacherStudentsRepositoryError.notAuthenticated
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedEmail.contains("@") else {
            throw TeacherStudentsRepositoryError.invalidEmail
        }
        guard !normalizedMessage.isEmpty else {
            throw TeacherStudentsRepositoryError.emptyMessage
        }

        let notificationCenter = database.collection("notifications").document("invitations")
        let notification = notificationCenter.collection("items").document()
        let batch = database.batch()
        batch.setData([
            "type": "emailInvitations",
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: notificationCenter, merge: true)
        batch.setData([
            "id": notification.documentID,
            "senderId": teacher.uid,
            "senderRole": "teacher",
            "senderName": teacher.displayName ?? teacher.email ?? "Репетитор",
            "senderEmail": teacher.email ?? "",
            "recipientRole": "student",
            "recipientEmail": normalizedEmail,
            "title": "Приглашение от репетитора",
            "message": normalizedMessage,
            "type": "emailInvitation",
            "deliveryStatus": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: notification)
        try await batch.commit()
    }

    private var localEntity: String {
        "teacher_local_student_\(Auth.auth().currentUser?.uid ?? "local")"
    }

    private func sorted(_ students: [TeacherLocalStudent]) -> [TeacherLocalStudent] {
        students.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}

enum TeacherStudentsRepositoryError: LocalizedError {
    case notAuthenticated
    case invalidEmail
    case emptyMessage
    case studentNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Не удалось определить аккаунт учителя"
        case .invalidEmail:
            return "Проверьте email ученика"
        case .emptyMessage:
            return "Введите сообщение"
        case .studentNotFound:
            return "Ученик не найден. Проверьте короткий ID или email."
        }
    }
}
