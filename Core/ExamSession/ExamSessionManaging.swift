import Foundation

protocol ExamSessionManaging {
    func activeSession() async throws -> ExamSession?
    func activeSession(datasetID: String) async throws -> ExamSession?
    func session(id: ExamSession.ID) async throws -> ExamSession?
    func startSession(examID: String, datasetID: String, subjectID: String, subjectTitle: String, kind: ExamSessionKind, taskIDs: [EducationalTask.ID], durationSeconds: Int?, proctoringConsent: ExamProctoringConsent?) async throws -> ExamSession
    func saveAnswer(_ answer: String?, taskID: EducationalTask.ID, sessionID: ExamSession.ID) async throws
    func updateStatus(_ status: ExamSessionStatus, for sessionID: ExamSession.ID) async throws
    func updateProctoringConsent(_ consent: ExamProctoringConsent, for sessionID: ExamSession.ID) async throws
    func markSafeSessionInvalid(for sessionID: ExamSession.ID) async throws
    func markTimeExpired(for sessionID: ExamSession.ID) async throws
}

struct DefaultExamSessionManager: ExamSessionManaging {
    let store: ExamSessionStore

    func activeSession() async throws -> ExamSession? {
        try await store.loadActiveSession()
    }

    func activeSession(datasetID: String) async throws -> ExamSession? {
        try await store.loadActiveSession(datasetID: datasetID)
    }

    func session(id: ExamSession.ID) async throws -> ExamSession? {
        try await store.loadSession(id: id)
    }

    func startSession(
        examID: String,
        datasetID: String,
        subjectID: String,
        subjectTitle: String,
        kind: ExamSessionKind,
        taskIDs: [EducationalTask.ID],
        durationSeconds: Int?,
        proctoringConsent: ExamProctoringConsent?
    ) async throws -> ExamSession {
        let session = ExamSession(
            examID: examID,
            datasetID: datasetID,
            subjectID: subjectID,
            subjectTitle: subjectTitle,
            kind: kind,
            taskIDs: taskIDs,
            status: .inProgress,
            durationSeconds: durationSeconds ?? 3_600,
            safeModeEnabled: proctoringConsent?.acceptedAgreement == true,
            safeSessionValid: proctoringConsent?.allowsCamera == true
                && proctoringConsent?.allowsMicrophone == true
                && proctoringConsent?.acceptedAgreement == true,
            proctoringConsent: proctoringConsent
        )
        try await store.save(session)
        return session
    }

    func saveAnswer(_ answer: String?, taskID: EducationalTask.ID, sessionID: ExamSession.ID) async throws {
        guard var session = try await store.loadSession(id: sessionID) else { return }
        if let answer, !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            session.answers[taskID] = answer
        } else {
            session.answers[taskID] = nil
        }
        session.updatedAt = Date()
        if session.status == .started {
            session.status = .inProgress
        }
        try await store.save(session)
    }

    func updateStatus(_ status: ExamSessionStatus, for sessionID: ExamSession.ID) async throws {
        guard var session = try await store.loadSession(id: sessionID) else { return }
        let now = Date()
        session.status = status
        session.updatedAt = now
        if status == .submitted {
            session.submittedAt = now
            session.actualDurationSeconds = Int(now.timeIntervalSince(session.startedAt))
        }
        if status == .interrupted || status == .cancelled {
            session.interruptedAt = now
            session.actualDurationSeconds = Int(now.timeIntervalSince(session.startedAt))
            session.safeSessionValid = false
        }
        try await store.save(session)
    }

    func updateProctoringConsent(_ consent: ExamProctoringConsent, for sessionID: ExamSession.ID) async throws {
        guard var session = try await store.loadSession(id: sessionID) else { return }
        session.proctoringConsent = consent
        session.updatedAt = Date()
        try await store.save(session)
    }

    func markSafeSessionInvalid(for sessionID: ExamSession.ID) async throws {
        guard var session = try await store.loadSession(id: sessionID) else { return }
        session.safeSessionValid = false
        session.updatedAt = Date()
        try await store.save(session)
    }

    func markTimeExpired(for sessionID: ExamSession.ID) async throws {
        guard var session = try await store.loadSession(id: sessionID) else { return }
        if session.timeExpiredAt == nil {
            session.timeExpiredAt = Date()
        }
        session.updatedAt = Date()
        try await store.save(session)
    }
}
