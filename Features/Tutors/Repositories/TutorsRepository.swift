import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol TutorsRepository {
    func loadTutors(filters: TutorFilters) async throws -> [TutorConnection]
    func loadAssignments(filters: TutorFilters) async throws -> [TutorAssignment]
    func addTutor(_ request: AddTutorRequest) async throws
    func inviteTutor(email: String) async throws
    func removeTutor(_ tutor: TutorConnection) async throws
    func prepareAssignmentExam(id: String) async throws -> ExamConstructorStartContext
    func submitAssignment(id: String) async throws
}

struct DefaultTutorsRepository: TutorsRepository {
    private let database = Firestore.firestore()
    private let contentStore: EducationalContentStore

    init(contentStore: EducationalContentStore) {
        self.contentStore = contentStore
    }

    func loadTutors(filters: TutorFilters) async throws -> [TutorConnection] {
        guard let studentID = currentStudentID else { return [] }

        let student = try await database
            .collection("students")
            .document(studentID)
            .getDocument()
        let teacherIDs = student.data()?["teacherIds"] as? [String] ?? []

        var connections: [TutorConnection] = []

        for teacherID in teacherIDs {
            let profile = try await database.collection("teachers").document(teacherID).getDocument()
            guard let data = profile.data() else { continue }
            let subjectID = data["subjectId"] as? String ?? "math"
            if let filterSubjectID = filters.subjectID, filterSubjectID != subjectID {
                continue
            }

            connections.append(TutorConnection(
                id: teacherID,
                tutorID: data["publicToken"] as? String ?? "",
                tutorUid: teacherID,
                name: data["name"] as? String ?? "Репетитор",
                email: data["email"] as? String ?? "",
                subject: Subject(
                    id: subjectID,
                    title: data["subjectTitle"] as? String ?? subjectTitle(for: subjectID)
                ),
                totalAssignments: 0,
                completedAssignments: 0,
                pendingNotifications: 0
            ))
        }

        return connections.sorted { $0.name < $1.name }
    }

    func loadAssignments(filters: TutorFilters) async throws -> [TutorAssignment] {
        guard let studentID = currentStudentID else { return [] }

        let snapshot = try await database
            .collection("assignments")
            .whereField("studentId", isEqualTo: studentID)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()
            let subjectID = data["subjectId"] as? String ?? "math"
            let dueAt = (data["dueAt"] as? Timestamp)?.dateValue()
            if let filterSubjectID = filters.subjectID, filterSubjectID != subjectID {
                return nil
            }

            return TutorAssignment(
                id: document.documentID,
                title: data["title"] as? String ?? subjectTitle(for: subjectID),
                subject: Subject(
                    id: subjectID,
                    title: data["subjectTitle"] as? String ?? subjectTitle(for: subjectID)
                ),
                tutorEmail: data["tutorEmail"] as? String ?? "",
                dueTitle: dueAt.map(Self.dueTitle) ?? "Срок не указан",
                remainingTitle: dueAt.map(Self.remainingTitle) ?? "",
                durationSeconds: data["durationSeconds"] as? Int ?? 3_600,
                variantVersionID: data["variantVersionId"] as? String ?? "",
                isSubmitted: data["status"] as? String == "submitted"
            )
        }
    }

    func prepareAssignmentExam(id: String) async throws -> ExamConstructorStartContext {
        let assignment = try await database.collection("assignments").document(id).getDocument()
        guard let data = assignment.data(),
              let versionID = data["variantVersionId"] as? String,
              !versionID.isEmpty else {
            throw TutorRepositoryError.assignmentNotFound
        }
        guard data["status"] as? String != "submitted" else {
            throw TutorRepositoryError.assignmentAlreadySubmitted
        }

        let snapshot = try await database
            .collection("assignmentVariantVersions")
            .document(versionID)
            .collection("items")
            .getDocuments()
        let documents = snapshot.documents.sorted {
            ($0.data()["position"] as? Int ?? 0) < ($1.data()["position"] as? Int ?? 0)
        }
        var tasks: [EducationalTask] = []

        for document in documents {
            let item = document.data()
            if item["kind"] as? String == TeacherAssignmentItemKind.seed.rawValue,
               let datasetID = item["datasetId"] as? String,
               let taskID = item["taskId"] as? String,
               let source = try await contentStore.loadDatabase(datasetID: datasetID),
               let task = source.tasks.first(where: { $0.id == taskID }) {
                tasks.append(task)
            } else if item["kind"] as? String == TeacherAssignmentItemKind.custom.rawValue {
                let contentType = item["attachmentContentType"] as? String ?? ""
                tasks.append(
                    EducationalTask(
                        id: document.documentID,
                        questionNumber: "\(tasks.count + 1)",
                        topic: "Задание репетитора",
                        questionHTML: item["taskText"] as? String ?? "",
                        drawingURL: contentType.hasPrefix("image/") ? item["attachmentUrl"] as? String : nil,
                        explanationDrawingURL: nil,
                        answerDrawingURL: nil,
                        audioURL: nil,
                        answerType: nil,
                        answer: item["answerText"] as? String ?? "",
                        difficulty: nil,
                        resourceID: nil,
                        explanationHTML: item["explanationText"] as? String,
                        subjectID: data["subjectId"] as? String ?? "math",
                        examCategory: .constructor,
                        level: nil,
                        blockID: "teacher-assignment"
                    )
                )
            }
        }

        guard !tasks.isEmpty else {
            throw TutorRepositoryError.assignmentHasNoTasks
        }

        let datasetID = "teacher-assignment-\(id)"
        let subjectID = data["subjectId"] as? String ?? tasks.first?.subjectID ?? "math"
        let title = data["title"] as? String ?? "Задание репетитора"
        try await contentStore.replaceContent(
            EducationalContentDatabase(
                datasetID: datasetID,
                title: title,
                subject: Subject(id: subjectID, title: subjectTitle(for: subjectID)),
                examCategory: .constructor,
                level: nil,
                version: 1,
                source: "teacher-assignment",
                blocks: [
                    EducationalContentBlock(
                        id: "teacher-assignment",
                        title: title,
                        subjectID: subjectID,
                        examCategory: .constructor,
                        taskIDs: tasks.map(\.id)
                    )
                ],
                tasks: tasks
            )
        )

        return ExamConstructorStartContext(
            datasetID: datasetID,
            title: title,
            taskIDs: tasks.map(\.id),
            durationSeconds: data["durationSeconds"] as? Int ?? 3_600,
            assignmentID: id
        )
    }

    func submitAssignment(id: String) async throws {
        guard let student = Auth.auth().currentUser else { return }
        let reference = database.collection("assignments").document(id)
        let snapshot = try await reference.getDocument()
        guard let data = snapshot.data(),
              data["studentId"] as? String == student.uid else {
            throw TutorRepositoryError.assignmentNotFound
        }
        guard data["status"] as? String != "submitted" else { return }

        let timestamp = FieldValue.serverTimestamp()
        let batch = database.batch()
        batch.setData([
            "status": "submitted",
            "submittedAt": timestamp,
            "updatedAt": timestamp
        ], forDocument: reference, merge: true)

        if let teacherID = data["teacherId"] as? String, !teacherID.isEmpty {
            let category = database.collection("notifications").document("assignments")
            batch.setData([
                "type": "assignments",
                "updatedAt": timestamp
            ], forDocument: category, merge: true)
            batch.setData([
                "assignmentId": id,
                "senderId": student.uid,
                "senderName": student.displayName ?? student.email ?? "Ученик",
                "recipientId": teacherID,
                "title": "Задание сдано",
                "message": "\(student.displayName ?? student.email ?? "Ученик") выполнил задание «\(data["title"] as? String ?? "Домашнее задание")».",
                "type": "assignment",
                "status": "informational",
                "isRead": false,
                "createdAt": timestamp,
                "updatedAt": timestamp
            ], forDocument: category.collection("items").document("submitted-\(id)"), merge: true)
        }

        try await batch.commit()
    }

    func addTutor(_ request: AddTutorRequest) async throws {
        guard let user = Auth.auth().currentUser else { return }

        let studentID = user.uid
        let normalizedEmail = request.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedTutorID = request.tutorID.trimmingCharacters(in: .whitespacesAndNewlines)
        let teacherProfile = try await resolveTeacherProfile(
            tutorID: normalizedTutorID,
            email: normalizedEmail
        )
        let requestID = "\(studentID)_\(teacherProfile.uid)"
        let timestamp = FieldValue.serverTimestamp()
        let studentName = user.displayName ?? user.email ?? "Ученик"
        let batch = database.batch()
        let notificationCenter = database.collection("notifications").document("connectionRequests")
        batch.setData([
            "type": "connectionRequests",
            "updatedAt": timestamp
        ], forDocument: notificationCenter, merge: true)
        batch.setData([
            "id": requestID,
            "requestId": requestID,
            "senderId": studentID,
            "senderRole": "student",
            "senderName": studentName,
            "senderEmail": user.email ?? "",
            "recipientId": teacherProfile.uid,
            "recipientRole": "teacher",
            "recipientName": teacherProfile.name,
            "recipientEmail": teacherProfile.email,
            "title": "Запрос на добавление",
            "message": "\(studentName) хочет добавить вас как репетитора.",
            "type": "invitation",
            "status": "pending",
            "isRead": false,
            "createdAt": timestamp,
            "updatedAt": timestamp
        ], forDocument: notificationCenter.collection("items").document(requestID), merge: true)
        try await batch.commit()
    }

    func inviteTutor(email: String) async throws {
        guard let user = Auth.auth().currentUser else { return }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.contains("@") else {
            throw TutorRepositoryError.invalidEmail
        }

        let requestID = UUID().uuidString
        let studentName = user.displayName ?? user.email ?? "Ученик"
        let timestamp = FieldValue.serverTimestamp()
        let commonPayload: [String: Any] = [
            "id": requestID,
            "requestId": requestID,
            "senderId": user.uid,
            "senderRole": "student",
            "senderName": studentName,
            "senderEmail": user.email ?? "",
            "recipientRole": "teacher",
            "recipientEmail": normalizedEmail,
            "studentId": user.uid,
            "status": "pending",
            "createdAt": timestamp,
            "updatedAt": timestamp
        ]
        let batch = database.batch()
        let category = database.collection("notifications").document("invitations")
        batch.setData([
            "type": "emailInvitations",
            "updatedAt": timestamp
        ], forDocument: category, merge: true)
        batch.setData(commonPayload.merging([
            "title": "Приглашение в ExamUp",
            "message": "\(studentName) приглашает вас стать репетитором в ExamUp.",
            "type": "emailInvitation",
            "deliveryStatus": "pending"
        ]) { _, new in new }, forDocument: category.collection("items").document(requestID), merge: true)
        try await batch.commit()
    }

    func removeTutor(_ tutor: TutorConnection) async throws {
        guard let user = Auth.auth().currentUser else { return }

        let studentID = user.uid
        let timestamp = FieldValue.serverTimestamp()

        let batch = database.batch()
        batch.setData([
            "teacherIds": FieldValue.arrayRemove([tutor.tutorUid]),
            "updatedAt": timestamp
        ], forDocument: database.collection("students").document(studentID), merge: true)
        batch.setData([
            "studentIds": FieldValue.arrayRemove([studentID]),
            "updatedAt": timestamp
        ], forDocument: database.collection("teachers").document(tutor.tutorUid), merge: true)
        try await batch.commit()

        if !tutor.tutorUid.isEmpty {
            let category = database.collection("notifications").document("personal")
            let batch = database.batch()
            batch.setData([
                "type": "personal",
                "updatedAt": timestamp
            ], forDocument: category, merge: true)
            batch.setData([
                    "recipientId": tutor.tutorUid,
                    "title": "Ученик удалил связь",
                    "message": "\(user.displayName ?? user.email ?? "Ученик") удалил вас из списка репетиторов.",
                    "type": "system",
                    "isRead": false,
                    "studentId": studentID,
                    "createdAt": timestamp
                ], forDocument: category.collection("items").document(), merge: true)
            try await batch.commit()
        }
    }

    private var currentStudentID: String? {
        Auth.auth().currentUser?.uid
    }

    private func subjectTitle(for subjectID: String) -> String {
        switch subjectID {
        case "math": return "Математика"
        case "russian": return "Русский язык"
        case "history": return "История"
        default: return "Предмет"
        }
    }

    private static func dueTitle(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "ru_RU")))
    }

    private static func remainingTitle(_ date: Date) -> String {
        let seconds = Int(date.timeIntervalSinceNow)
        guard seconds > 0 else { return "Срок истек" }
        let days = seconds / 86_400
        if days > 0 { return "\(days) дн." }
        return "\(max(1, seconds / 3_600)) ч."
    }

    private func resolveTeacherProfile(tutorID: String, email: String) async throws -> ResolvedTeacherProfile {
        if !tutorID.isEmpty {
            let snapshot = try await database
                .collection("teachers")
                .whereField("publicToken", isEqualTo: tutorID)
                .limit(to: 1)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                throw TutorRepositoryError.teacherNotFound
            }
            let data = document.data()

            let subjectID = data["subjectId"] as? String ?? "math"
            return ResolvedTeacherProfile(
                publicId: data["publicToken"] as? String ?? tutorID,
                uid: document.documentID,
                name: data["name"] as? String ?? "Репетитор",
                email: data["email"] as? String ?? "",
                subject: Subject(
                    id: subjectID,
                    title: data["subjectTitle"] as? String ?? subjectTitle(for: subjectID)
                )
            )
        }

        guard email.contains("@") else {
            throw TutorRepositoryError.missingIdentifier
        }

        let snapshot = try await database
            .collection("teachers")
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw TutorRepositoryError.teacherNotFound
        }

        let data = document.data()
        let publicId = data["publicToken"] as? String ?? AppUserIDGenerator.sixDigitID(from: document.documentID)

        return ResolvedTeacherProfile(
            publicId: publicId,
            uid: document.documentID,
            name: data["name"] as? String ?? "Репетитор",
            email: data["email"] as? String ?? email,
            subject: Subject(
                id: data["subjectId"] as? String ?? "math",
                title: data["subjectTitle"] as? String ?? subjectTitle(for: data["subjectId"] as? String ?? "math")
            )
        )
    }

    private func loadTeacherProfile(tutorID: String, tutorUid: String?, email: String?) async throws -> ResolvedTeacherProfile {
        if let tutorUid, !tutorUid.isEmpty {
            let document = try await database
                .collection("teachers")
                .document(tutorUid)
                .getDocument()

            if let data = document.data() {
                let subjectID = data["subjectId"] as? String ?? "math"
                return ResolvedTeacherProfile(
                    publicId: data["publicToken"] as? String ?? tutorID,
                    uid: tutorUid,
                    name: data["name"] as? String ?? "Репетитор",
                    email: data["email"] as? String ?? email ?? "",
                    subject: Subject(
                        id: subjectID,
                        title: data["subjectTitle"] as? String ?? subjectTitle(for: subjectID)
                    )
                )
            }
        }

        return ResolvedTeacherProfile(
            publicId: tutorID,
            uid: tutorUid ?? "",
            name: "Репетитор",
            email: email ?? "",
            subject: nil
        )
    }
}

private struct ResolvedTeacherProfile {
    let publicId: String
    let uid: String
    let name: String
    let email: String
    let subject: Subject?
}

enum TutorRepositoryError: LocalizedError {
    case missingIdentifier
    case teacherNotFound
    case invalidEmail
    case assignmentNotFound
    case assignmentHasNoTasks
    case assignmentAlreadySubmitted

    var errorDescription: String? {
        switch self {
        case .missingIdentifier:
            return "Введите ID репетитора или email, если ID нет."
        case .teacherNotFound:
            return "Репетитор не найден. Проверьте ID или email."
        case .invalidEmail:
            return "Введите корректный email репетитора."
        case .assignmentNotFound:
            return "Не удалось найти назначенное задание."
        case .assignmentHasNoTasks:
            return "В назначенном задании нет доступных вопросов."
        case .assignmentAlreadySubmitted:
            return "Это задание уже сдано. Повторная попытка недоступна."
        }
    }
}

private extension String {
    var firestoreDocumentID: String {
        replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
