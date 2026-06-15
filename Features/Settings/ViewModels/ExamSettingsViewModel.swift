import SwiftUI

@MainActor
final class ExamSettingsViewModel: ObservableObject {
    @AppStorage("exam.defaultDurationMinutes") var defaultDurationMinutes = 180
    @AppStorage("exam.showTimer")              var showTimer              = true
    @AppStorage("exam.confirmBeforeFinish")    var confirmBeforeFinish    = true
    @AppStorage("exam.autoNextQuestion")       var autoNextQuestion       = false

    let durationOptions: [(label: String, minutes: Int)] = [
        ("30 минут",   30),
        ("1 час",      60),
        ("1.5 часа",   90),
        ("2 часа",     120),
        ("3 часа",     180),
        ("4 часа",     240),
    ]

    var selectedDurationLabel: String {
        durationOptions.first { $0.minutes == defaultDurationMinutes }?.label
            ?? "\(defaultDurationMinutes) мин"
    }
}
