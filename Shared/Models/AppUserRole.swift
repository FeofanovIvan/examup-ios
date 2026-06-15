import Foundation

enum AppUserRole: String, Codable, CaseIterable, Identifiable {
    case student
    case teacher

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: return "Я ученик"
        case .teacher: return "Я учитель"
        }
    }
}
