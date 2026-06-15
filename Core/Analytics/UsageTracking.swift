import Foundation

protocol UsageTracking {
    func recordExamStarted(session: ExamSession) async
    func recordAnswerSaved(sessionID: ExamSession.ID, taskID: EducationalTask.ID, hasAnswer: Bool) async
    func recordExamStatusChanged(session: ExamSession, status: ExamSessionStatus) async
    func loadUsageSummary() async -> UsageSummary
}

struct UsageSummary: Codable, Equatable {
    var startedExamCount: Int = 0
    var completedExamCount: Int = 0
    var savedAnswerCount: Int = 0
    var currentStreakDays: Int = 0
    var lastActivityDate: Date?
}

struct NoOpUsageTracker: UsageTracking {
    func recordExamStarted(session: ExamSession) async {}
    func recordAnswerSaved(sessionID: ExamSession.ID, taskID: EducationalTask.ID, hasAnswer: Bool) async {}
    func recordExamStatusChanged(session: ExamSession, status: ExamSessionStatus) async {}
    func loadUsageSummary() async -> UsageSummary { UsageSummary() }
}

actor UserDefaultsUsageTracker: UsageTracking {
    private let defaults: UserDefaults
    private let analytics: AnalyticsTracking
    private let key = "usage.summary.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var startedSessionIDs: Set<ExamSession.ID> = []
    private var completedSessionIDs: Set<ExamSession.ID> = []
    private var answeredKeys: Set<String> = []

    init(defaults: UserDefaults = .standard, analytics: AnalyticsTracking) {
        self.defaults = defaults
        self.analytics = analytics
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func recordExamStarted(session: ExamSession) async {
        guard startedSessionIDs.insert(session.id).inserted else { return }
        var summary = loadStoredSummary()
        summary.startedExamCount += 1
        summary.registerActivity(on: Date())
        save(summary)
        analytics.track(
            AnalyticsEvent(
                name: "exam_started",
                properties: [
                    "session_id": session.id,
                    "dataset_id": session.datasetID,
                    "kind": session.kind.rawValue,
                    "subject_id": session.subjectID
                ]
            )
        )
    }

    func recordAnswerSaved(sessionID: ExamSession.ID, taskID: EducationalTask.ID, hasAnswer: Bool) async {
        guard hasAnswer else { return }
        let key = "\(sessionID):\(taskID)"
        guard answeredKeys.insert(key).inserted else { return }
        var summary = loadStoredSummary()
        summary.savedAnswerCount += 1
        summary.registerActivity(on: Date())
        save(summary)
        analytics.track(
            AnalyticsEvent(
                name: "answer_saved",
                properties: [
                    "session_id": sessionID,
                    "task_id": taskID
                ]
            )
        )
    }

    func recordExamStatusChanged(session: ExamSession, status: ExamSessionStatus) async {
        var summary = loadStoredSummary()
        summary.registerActivity(on: Date())
        if status == .submitted, completedSessionIDs.insert(session.id).inserted {
            summary.completedExamCount += 1
        }
        save(summary)
        analytics.track(
            AnalyticsEvent(
                name: "exam_status_changed",
                properties: [
                    "session_id": session.id,
                    "dataset_id": session.datasetID,
                    "status": status.rawValue
                ]
            )
        )
    }

    func loadUsageSummary() async -> UsageSummary {
        loadStoredSummary()
    }

    private func loadStoredSummary() -> UsageSummary {
        guard let data = defaults.data(forKey: key),
              let summary = try? decoder.decode(UsageSummary.self, from: data) else {
            return UsageSummary()
        }
        return summary
    }

    private func save(_ summary: UsageSummary) {
        guard let data = try? encoder.encode(summary) else { return }
        defaults.set(data, forKey: key)
    }
}

private extension UsageSummary {
    mutating func registerActivity(on date: Date, calendar: Calendar = .current) {
        defer { lastActivityDate = date }
        guard let lastActivityDate else {
            currentStreakDays = 1
            return
        }
        if calendar.isDate(lastActivityDate, inSameDayAs: date) {
            currentStreakDays = max(currentStreakDays, 1)
            return
        }
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastActivityDate)),
           calendar.isDate(nextDay, inSameDayAs: date) {
            currentStreakDays += 1
        } else {
            currentStreakDays = 1
        }
    }
}
