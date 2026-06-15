import Foundation

struct ExamResultReport: Identifiable, Equatable {
    let id: String
    let title: String
    let subjectTitle: String
    let kindTitle: String
    let completedAt: Date
    let durationSeconds: Int
    let safeSessionValid: Bool
    let safeModeReport: ExamSafeModeReport?
    let items: [ExamResultReportItem]

    var answeredCount: Int {
        items.filter(\.hasUserAnswer).count
    }

    var totalCount: Int {
        items.count
    }
}

struct ExamResultReportItem: Identifiable, Equatable {
    let id: String
    let subjectID: String?
    let number: String
    let topic: String
    let questionHTML: String
    let drawingURL: String?
    let audioURL: String?
    let userAnswer: String?
    let correctAnswer: String
    let answerDrawingURL: String?
    let explanationHTML: String?
    let explanationDrawingURL: String?

    var hasUserAnswer: Bool {
        guard let userAnswer else { return false }
        return !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
