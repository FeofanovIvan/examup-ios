import Foundation

protocol CalendarRepository {
    func loadHistoryItems() async throws -> [ExamHistoryItem]
    func loadResultReport(id: ExamHistoryItem.ID) async throws -> ExamResultReport?
    func deleteHistoryItem(id: ExamHistoryItem.ID) async throws
}

struct DefaultCalendarRepository: CalendarRepository {
    private let examSessionStore: ExamSessionStore
    private let contentStore: EducationalContentStore

    init(examSessionStore: ExamSessionStore, contentStore: EducationalContentStore) {
        self.examSessionStore = examSessionStore
        self.contentStore = contentStore
    }

    func loadHistoryItems() async throws -> [ExamHistoryItem] {
        try await examSessionStore.loadAllSessions()
            .filter { $0.status == .submitted }
            .sorted { ($0.submittedAt ?? $0.updatedAt) > ($1.submittedAt ?? $1.updatedAt) }
            .map { session in
                ExamHistoryItem(
                    id: session.id,
                    subjectTitle: session.subjectTitle.isEmpty ? subjectTitle(for: session.subjectID) : session.subjectTitle,
                    kindTitle: session.kind.title,
                    detail: detail(for: session),
                    completedAt: session.submittedAt ?? session.updatedAt,
                    durationSeconds: session.actualDurationSeconds ?? Int((session.submittedAt ?? session.updatedAt).timeIntervalSince(session.startedAt)),
                    safeSessionValid: session.safeSessionValid,
                    subjectID: session.subjectID
                )
            }
    }

    func loadResultReport(id: ExamHistoryItem.ID) async throws -> ExamResultReport? {
        guard let session = try await examSessionStore.loadSession(id: id),
              let database = try await contentStore.loadDatabase(datasetID: session.datasetID) else {
            return nil
        }

        let tasksByID = Dictionary(uniqueKeysWithValues: database.tasks.map { ($0.id, $0) })
        let orderedTasks = session.taskIDs.compactMap { tasksByID[$0] }
        let reportTasks = orderedTasks.isEmpty ? database.tasks : orderedTasks
        let items = reportTasks.enumerated().map { index, task in
            ExamResultReportItem(
                id: task.id,
                subjectID: task.subjectID,
                number: task.questionNumber ?? "\(index + 1)",
                topic: task.topic,
                questionHTML: task.questionHTML,
                drawingURL: task.drawingURL,
                audioURL: task.audioURL,
                userAnswer: session.answers[task.id],
                correctAnswer: task.answer,
                answerDrawingURL: task.answerDrawingURL,
                explanationHTML: task.explanationHTML,
                explanationDrawingURL: task.explanationDrawingURL
            )
        }

        return ExamResultReport(
            id: session.id,
            title: session.examID,
            subjectTitle: session.subjectTitle.isEmpty ? subjectTitle(for: session.subjectID) : session.subjectTitle,
            kindTitle: session.kind.title,
            completedAt: session.submittedAt ?? session.updatedAt,
            durationSeconds: session.actualDurationSeconds ?? Int((session.submittedAt ?? session.updatedAt).timeIntervalSince(session.startedAt)),
            safeSessionValid: session.safeSessionValid,
            safeModeReport: ExamArchiveShareService.loadReport(for: session.id),
            items: items
        )
    }

    func deleteHistoryItem(id: ExamHistoryItem.ID) async throws {
        try await examSessionStore.deleteSession(id: id)
        try ExamArchiveShareService.deleteArchive(for: id)
    }

    private func detail(for session: ExamSession) -> String {
        if session.kind == .constructor {
            return "Созданный вариант"
        }

        if session.datasetID == SeedDatasetID.mathEGEBase.rawValue {
            return "Базовый уровень"
        }

        if session.datasetID == SeedDatasetID.mathEGEProfile.rawValue {
            return "Профильный уровень"
        }

        return "Вариант \(session.taskIDs.count)"
    }

    private func subjectTitle(for subjectID: String) -> String {
        switch subjectID {
        case "math": return "Математика"
        case "russian": return "Русский язык"
        case "history": return "История"
        default: return "Предмет"
        }
    }
}
