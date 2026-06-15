import Foundation

struct ExamHistoryDashboard: Equatable {
    let selectedDate: Date
    let items: [ExamHistoryItem]

    static let empty = ExamHistoryDashboard(selectedDate: Date(), items: [])
}

struct ExamHistoryItem: Identifiable, Equatable {
    let id: String
    let subjectTitle: String
    let kindTitle: String
    let detail: String
    let completedAt: Date
    let durationSeconds: Int
    let safeSessionValid: Bool
    let subjectID: String
}

struct CalendarDaySchedule: Identifiable, Codable, Equatable {
    let id: String
    let monthTitle: String
    let selectedDay: StudentCalendarDay
    let weekDays: [StudentCalendarDay]
    let events: [StudentCalendarEvent]

    static let placeholder = CalendarDaySchedule(
        id: "placeholder",
        monthTitle: "",
        selectedDay: StudentCalendarDay(weekday: "", number: "", isSelected: false, hasEvent: false, isWeekend: false),
        weekDays: [],
        events: []
    )
}

struct StudentCalendarDay: Identifiable, Codable, Equatable {
    var id: String { "\(weekday)-\(number)" }
    let weekday: String
    let number: String
    let isSelected: Bool
    let hasEvent: Bool
    let isWeekend: Bool
}

struct StudentCalendarEvent: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let time: String
    let owner: String
    let imageName: String
    let tintHex: String
    let backgroundHex: String
}
