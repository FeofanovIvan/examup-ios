import Foundation

enum TeacherAssignmentHistoryFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case pending = "Не сдано"
    case submitted = "Сдано"

    var id: String { rawValue }
}

struct TeacherAssignmentHistoryItem: Identifiable, Equatable {
    let id: String
    let title: String
    let studentID: String
    let studentName: String
    let studentPublicID: String
    let dueAt: Date
    let submittedAt: Date?
    let versionID: String
    let subjectID: String

    var isSubmitted: Bool { submittedAt != nil }
}
