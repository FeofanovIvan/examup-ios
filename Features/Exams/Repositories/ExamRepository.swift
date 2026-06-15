import Foundation

protocol ExamRepository {
    func activeSession() async throws -> ExamSession?
    func activeSession(datasetID: String) async throws -> ExamSession?
    func session(id: ExamSession.ID) async throws -> ExamSession?
    func startSession(for exam: Exam) async throws -> ExamSession
    func startSession(datasetID: String, title: String, subjectID: String, subjectTitle: String, kind: ExamSessionKind, taskIDs: [EducationalTask.ID], durationSeconds: Int?, proctoringConsent: ExamProctoringConsent?) async throws -> ExamSession
    func saveAnswer(_ answer: String?, taskID: EducationalTask.ID, sessionID: ExamSession.ID) async throws
    func updateSessionStatus(_ status: ExamSessionStatus, sessionID: ExamSession.ID) async throws
    func updateProctoringConsent(_ consent: ExamProctoringConsent, sessionID: ExamSession.ID) async throws
    func markSafeSessionInvalid(sessionID: ExamSession.ID) async throws
    func markTimeExpired(sessionID: ExamSession.ID) async throws
}

struct DefaultExamRepository: ExamRepository {
    private let sessionManager: ExamSessionManaging
    private let resultRepository: ExamResultRepository
    private let usageTracker: UsageTracking

    init(
        examSessionStore: ExamSessionStore,
        resultRepository: ExamResultRepository = NoOpExamResultRepository(),
        usageTracker: UsageTracking
    ) {
        self.sessionManager = DefaultExamSessionManager(store: examSessionStore)
        self.resultRepository = resultRepository
        self.usageTracker = usageTracker
    }

    func activeSession() async throws -> ExamSession? {
        try await sessionManager.activeSession()
    }

    func activeSession(datasetID: String) async throws -> ExamSession? {
        try await sessionManager.activeSession(datasetID: datasetID)
    }

    func session(id: ExamSession.ID) async throws -> ExamSession? {
        try await sessionManager.session(id: id)
    }

    func startSession(for exam: Exam) async throws -> ExamSession {
        let session = try await sessionManager.startSession(
            examID: exam.id,
            datasetID: exam.id,
            subjectID: exam.subjectID,
            subjectTitle: exam.subjectID,
            kind: .ege,
            taskIDs: [],
            durationSeconds: nil,
            proctoringConsent: nil
        )
        await usageTracker.recordExamStarted(session: session)
        return session
    }

    func startSession(
        datasetID: String,
        title: String,
        subjectID: String,
        subjectTitle: String,
        kind: ExamSessionKind,
        taskIDs: [EducationalTask.ID],
        durationSeconds: Int?,
        proctoringConsent: ExamProctoringConsent?
    ) async throws -> ExamSession {
        let session = try await sessionManager.startSession(
            examID: title,
            datasetID: datasetID,
            subjectID: subjectID,
            subjectTitle: subjectTitle,
            kind: kind,
            taskIDs: taskIDs,
            durationSeconds: durationSeconds,
            proctoringConsent: proctoringConsent
        )
        await usageTracker.recordExamStarted(session: session)
        return session
    }

    func saveAnswer(_ answer: String?, taskID: EducationalTask.ID, sessionID: ExamSession.ID) async throws {
        try await sessionManager.saveAnswer(answer, taskID: taskID, sessionID: sessionID)
        await usageTracker.recordAnswerSaved(
            sessionID: sessionID,
            taskID: taskID,
            hasAnswer: answer?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        )
    }

    func updateSessionStatus(_ status: ExamSessionStatus, sessionID: ExamSession.ID) async throws {
        try await sessionManager.updateStatus(status, for: sessionID)
        if let session = try await sessionManager.session(id: sessionID) {
            await usageTracker.recordExamStatusChanged(session: session, status: status)
        }
        if status == .submitted || status == .interrupted || status == .cancelled,
           let session = try await sessionManager.session(id: sessionID) {
            try await resultRepository.saveResult(for: session)
        }
    }

    func updateProctoringConsent(_ consent: ExamProctoringConsent, sessionID: ExamSession.ID) async throws {
        try await sessionManager.updateProctoringConsent(consent, for: sessionID)
    }

    func markSafeSessionInvalid(sessionID: ExamSession.ID) async throws {
        try await sessionManager.markSafeSessionInvalid(for: sessionID)
    }

    func markTimeExpired(sessionID: ExamSession.ID) async throws {
        try await sessionManager.markTimeExpired(for: sessionID)
    }
}
