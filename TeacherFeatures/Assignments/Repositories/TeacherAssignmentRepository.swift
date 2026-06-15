import Foundation
import FirebaseAuth
import FirebaseStorage

protocol TeacherAssignmentRepository {
    func publishAssignment(
        title: String,
        studentIDs: [String],
        durationSeconds: Int,
        questionCount: Int,
        dueAt: Date,
        seedItems: [TeacherAssignmentSeedItem],
        customDrafts: [TeacherCustomAssignmentDraft]
    ) async throws -> TeacherAssignmentPayload
}

struct FirestoreTeacherAssignmentRepository: TeacherAssignmentRepository {
    private let storage = Storage.storage()
    private let localDatabase: LocalDatabase
    private let syncService: SyncServicing

    init(localDatabase: LocalDatabase, syncService: SyncServicing) {
        self.localDatabase = localDatabase
        self.syncService = syncService
    }

    func publishAssignment(
        title: String,
        studentIDs: [String],
        durationSeconds: Int,
        questionCount: Int,
        dueAt: Date,
        seedItems: [TeacherAssignmentSeedItem],
        customDrafts: [TeacherCustomAssignmentDraft]
    ) async throws -> TeacherAssignmentPayload {
        guard let user = Auth.auth().currentUser else {
            throw TeacherAssignmentRepositoryError.unauthenticated
        }

        let teacherID = user.uid
        let teacherPublicID = AppUserIDGenerator.sixDigitID(from: teacherID)
        let variantID = UUID().uuidString
        let versionID = UUID().uuidString
        let batchID = UUID().uuidString
        let customItems = try await uploadCustomItems(
            drafts: customDrafts,
            teacherPublicID: teacherPublicID,
            assignmentID: variantID
        )

        let payload = TeacherAssignmentPayload(
            id: batchID,
            teacherPublicID: teacherPublicID,
            title: title,
            studentIDs: studentIDs,
            durationSeconds: durationSeconds,
            questionCount: questionCount,
            dueAt: dueAt,
            seedItems: seedItems,
            customItems: customItems
        )

        try await queue(
            variantDocument(
                id: variantID,
                currentVersionID: versionID,
                teacherID: teacherID,
                title: title
            ),
            collection: "assignmentVariants",
            id: variantID
        )
        try await queue(
            versionDocument(
                id: versionID,
                variantID: variantID,
                teacherID: teacherID,
                title: title,
                durationSeconds: durationSeconds,
                questionCount: questionCount,
                seedCount: seedItems.count,
                customCount: customItems.count
            ),
            collection: "assignmentVariantVersions",
            id: versionID
        )
        try await queueItems(seedItems, customItems: customItems, versionID: versionID)
        try await queue(
            batchDocument(
                id: batchID,
                variantID: variantID,
                versionID: versionID,
                teacherID: teacherID,
                studentIDs: studentIDs,
                dueAt: dueAt
            ),
            collection: "assignmentBatches",
            id: batchID
        )
        try await queue(
            notificationCategoryDocument(type: "assignments"),
            collection: "notifications",
            id: "assignments"
        )

        for studentID in studentIDs {
            let assignmentID = UUID().uuidString
            try await queue(
                assignmentDocument(
                    id: assignmentID,
                    batchID: batchID,
                    variantID: variantID,
                    versionID: versionID,
                    teacherID: teacherID,
                    studentID: studentID,
                    title: title,
                    durationSeconds: durationSeconds,
                    questionCount: questionCount,
                    dueAt: dueAt
                ),
                collection: "assignments",
                id: assignmentID
            )
            try await queue(
                assignmentNotificationDocument(
                    id: assignmentID,
                    teacherID: teacherID,
                    studentID: studentID,
                    title: title,
                    dueAt: dueAt
                ),
                collection: "notifications/assignments/items",
                id: assignmentID
            )
        }
        await syncService.scheduleSync(for: .exams)

        return payload
    }

    private func queue(_ document: SyncDocument, collection: String, id: String) async throws {
        try await localDatabase.saveRecord(document, entity: collection, id: id, syncStatus: .pending)
        try await localDatabase.enqueue(
            SyncMutation(collection: collection, documentID: id, operation: .set, payload: try document.encoded())
        )
    }

    private func queueItems(
        _ seedItems: [TeacherAssignmentSeedItem],
        customItems: [TeacherAssignmentCustomItem],
        versionID: String
    ) async throws {
        let collection = "assignmentVariantVersions/\(versionID)/items"
        for (index, item) in seedItems.enumerated() {
            try await queue(item.syncDocument(index: index), collection: collection, id: item.id)
        }
        for (offset, item) in customItems.enumerated() {
            try await queue(item.syncDocument(index: seedItems.count + offset), collection: collection, id: item.id)
        }
    }

    private func uploadCustomItems(
        drafts: [TeacherCustomAssignmentDraft],
        teacherPublicID: String,
        assignmentID: String
    ) async throws -> [TeacherAssignmentCustomItem] {
        var items: [TeacherAssignmentCustomItem] = []

        for (index, draft) in drafts.enumerated() where draft.isValid {
            let itemID = UUID().uuidString
            var attachment: TeacherAssignmentAttachment?

            if let attachmentDraft = draft.attachment {
                let filename = attachmentDraft.filename.isEmpty ? "attachment-\(index + 1)" : attachmentDraft.filename
                let path = "teacher_assignments/\(teacherPublicID)/\(assignmentID)/\(itemID)/\(filename)"
                let reference = storage.reference(withPath: path)
                let metadata = StorageMetadata()
                metadata.contentType = attachmentDraft.contentType
                _ = try await reference.putDataAsync(attachmentDraft.data, metadata: metadata)
                attachment = TeacherAssignmentAttachment(
                    url: try await reference.downloadURL().absoluteString,
                    storagePath: path,
                    filename: filename,
                    contentType: attachmentDraft.contentType,
                    originalBytes: attachmentDraft.originalBytes,
                    storedBytes: attachmentDraft.storedBytes
                )
            }

            items.append(
                TeacherAssignmentCustomItem(
                    id: itemID,
                    taskText: draft.trimmedTaskText,
                    answerText: draft.trimmedAnswerText,
                    explanationText: draft.trimmedExplanationText.isEmpty ? nil : draft.trimmedExplanationText,
                    attachment: attachment
                )
            )
        }

        return items
    }
}

private func notificationCategoryDocument(type: String) -> SyncDocument {
    SyncDocument(fields: [
        "type": .string(type),
        "updatedAt": .serverTimestamp
    ])
}

enum TeacherAssignmentRepositoryError: LocalizedError {
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Нужно войти в аккаунт учителя"
        }
    }
}

private func variantDocument(id: String, currentVersionID: String, teacherID: String, title: String) -> SyncDocument {
    SyncDocument(fields: [
        "id": .string(id),
        "creatorId": .string(teacherID),
        "title": .string(title),
        "currentVersionId": .string(currentVersionID),
        "deleted": .bool(false),
        "createdAt": .serverTimestamp,
        "updatedAt": .serverTimestamp
    ])
}

private func versionDocument(
    id: String,
    variantID: String,
    teacherID: String,
    title: String,
    durationSeconds: Int,
    questionCount: Int,
    seedCount: Int,
    customCount: Int
) -> SyncDocument {
    SyncDocument(fields: [
        "id": .string(id),
        "variantId": .string(variantID),
        "creatorId": .string(teacherID),
        "version": .int(1),
        "title": .string(title),
        "durationSeconds": .int(durationSeconds),
        "questionCount": .int(questionCount),
        "seedQuestionCount": .int(seedCount),
        "customQuestionCount": .int(customCount),
        "createdAt": .serverTimestamp
    ])
}

private func batchDocument(
    id: String,
    variantID: String,
    versionID: String,
    teacherID: String,
    studentIDs: [String],
    dueAt: Date
) -> SyncDocument {
    SyncDocument(fields: [
        "id": .string(id),
        "variantId": .string(variantID),
        "variantVersionId": .string(versionID),
        "teacherId": .string(teacherID),
        "studentIds": .strings(studentIDs),
        "dueAt": .date(dueAt),
        "createdAt": .serverTimestamp
    ])
}

private func assignmentDocument(
    id: String,
    batchID: String,
    variantID: String,
    versionID: String,
    teacherID: String,
    studentID: String,
    title: String,
    durationSeconds: Int,
    questionCount: Int,
    dueAt: Date
) -> SyncDocument {
    SyncDocument(fields: [
        "id": .string(id),
        "batchId": .string(batchID),
        "variantId": .string(variantID),
        "variantVersionId": .string(versionID),
        "teacherId": .string(teacherID),
        "studentId": .string(studentID),
        "title": .string(title),
        "durationSeconds": .int(durationSeconds),
        "questionCount": .int(questionCount),
        "dueAt": .date(dueAt),
        "status": .string("assigned"),
        "safeMode": .bool(true),
        "deleted": .bool(false),
        "createdAt": .serverTimestamp,
        "updatedAt": .serverTimestamp
    ])
}

private func assignmentNotificationDocument(
    id: String,
    teacherID: String,
    studentID: String,
    title: String,
    dueAt: Date
) -> SyncDocument {
    SyncDocument(fields: [
        "id": .string(id),
        "assignmentId": .string(id),
        "senderId": .string(teacherID),
        "recipientId": .string(studentID),
        "title": .string("Новое задание"),
        "message": .string("Вам назначено задание «\(title)»."),
        "type": .string("assignment"),
        "status": .string("informational"),
        "isRead": .bool(false),
        "dueAt": .date(dueAt),
        "createdAt": .serverTimestamp,
        "updatedAt": .serverTimestamp
    ])
}

private extension TeacherAssignmentSeedItem {
    func syncDocument(index: Int) -> SyncDocument {
        SyncDocument(fields: [
            "id": .string(id),
            "position": .int(index),
            "kind": .string(TeacherAssignmentItemKind.seed.rawValue),
            "datasetId": .string(datasetID),
            "taskId": .string(task.id),
            "questionNumber": .string(task.questionNumber ?? ""),
            "topic": .string(task.topic)
        ])
    }
}

private extension TeacherAssignmentCustomItem {
    func syncDocument(index: Int) -> SyncDocument {
        SyncDocument(fields: [
            "id": .string(id),
            "position": .int(index),
            "kind": .string(TeacherAssignmentItemKind.custom.rawValue),
            "taskText": .string(taskText),
            "answerText": .string(answerText),
            "explanationText": explanationText.map(SyncFieldValue.string) ?? .null,
            "attachmentUrl": attachment.map { .string($0.url) } ?? .null,
            "attachmentStoragePath": attachment.map { .string($0.storagePath) } ?? .null,
            "attachmentFilename": attachment.map { .string($0.filename) } ?? .null,
            "attachmentContentType": attachment.map { .string($0.contentType) } ?? .null,
            "attachmentOriginalBytes": attachment.map { .int($0.originalBytes) } ?? .null,
            "attachmentStoredBytes": attachment.map { .int($0.storedBytes) } ?? .null
        ])
    }
}
