import SwiftUI

@MainActor
final class NotificationsSettingsViewModel: ObservableObject {
    @AppStorage("notifications.exams")     var notifyExams     = true
    @AppStorage("notifications.deadlines") var notifyDeadlines = true
    @AppStorage("notifications.tutor")     var notifyTutor     = true
    @AppStorage("notifications.reminders") var notifyReminders = true
}
