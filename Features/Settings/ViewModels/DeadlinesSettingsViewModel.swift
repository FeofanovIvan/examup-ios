import SwiftUI

@MainActor
final class DeadlinesSettingsViewModel: ObservableObject {
    @AppStorage("deadlines.remindersEnabled")  var remindersEnabled  = true
    @AppStorage("deadlines.remindDaysBefore")  var remindDaysBefore  = 1
    @AppStorage("deadlines.morningReminder")   var morningReminder   = false
    @AppStorage("deadlines.reminderHour")      var reminderHour      = 9

    let daysOptions = [1, 2, 3, 5, 7]

    var daysLabel: String { "\(remindDaysBefore) \(dayWord(remindDaysBefore))" }

    var reminderTimeLabel: String {
        String(format: "%02d:00", reminderHour)
    }

    private func dayWord(_ n: Int) -> String {
        switch n {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}
