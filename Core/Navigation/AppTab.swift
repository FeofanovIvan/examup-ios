import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case tutors
    case calendar
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Главная"
        case .tutors: return "Репетиторы"
        case .calendar: return "История"
        case .settings: return "Настройки"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .tutors: return "person.2"
        case .calendar: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}
