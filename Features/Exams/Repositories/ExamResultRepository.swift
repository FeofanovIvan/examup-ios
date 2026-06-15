import Foundation
import FirebaseAuth

protocol ExamResultRepository {
    func saveResult(for session: ExamSession) async throws
}

struct NoOpExamResultRepository: ExamResultRepository {
    func saveResult(for session: ExamSession) async throws {}
}

struct FirestoreExamResultRepository: ExamResultRepository {
    private let localDatabase: LocalDatabase
    private let syncService: SyncServicing

    init(localDatabase: LocalDatabase, syncService: SyncServicing) {
        self.localDatabase = localDatabase
        self.syncService = syncService
    }

    func saveResult(for session: ExamSession) async throws {
        guard let user = Auth.auth().currentUser else { return }

        let result = SyncDocument(fields: [
            "id": .string(session.id),
            "studentId": .string(user.uid),
            "studentPublicToken": .string(AppUserIDGenerator.sixDigitID(from: user.uid)),
            "subjectId": .string(session.subjectID),
            "subjectTitle": .string(session.subjectTitle),
            "examType": .string(session.kind.rawValue),
            "datasetId": .string(session.datasetID),
            "examId": .string(session.examID),
            "status": .string(session.status.rawValue),
            "startedAt": .date(session.startedAt),
            "completedAt": .date(session.submittedAt ?? session.updatedAt),
            "interruptedAt": session.interruptedAt.map(SyncFieldValue.date) ?? .null,
            "timeExpiredAt": session.timeExpiredAt.map(SyncFieldValue.date) ?? .null,
            "durationSeconds": .int(session.durationSeconds),
            "actualDurationSeconds": .int(session.actualDurationSeconds ?? Int(Date().timeIntervalSince(session.startedAt))),
            "safeModeEnabled": .bool(session.safeModeEnabled),
            "safeSessionValid": .bool(session.safeSessionValid),
            "taskIds": .strings(session.taskIDs),
            "answers": .stringMap(session.answers),
            "updatedAt": .serverTimestamp
        ])
        try await localDatabase.saveRecord(result, entity: "submission", id: session.id, syncStatus: .pending)
        try await localDatabase.enqueue(
            SyncMutation(
                collection: "submissions",
                documentID: session.id,
                operation: .set,
                payload: try result.encoded()
            )
        )
        await syncService.scheduleSync(for: .exams)
    }
}
