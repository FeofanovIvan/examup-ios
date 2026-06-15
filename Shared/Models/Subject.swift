import Foundation

struct Subject: Identifiable, Codable, Hashable {
    let id: String
    let title: String

    static let placeholders = [
        Subject(id: "english", title: "Английский язык"),
        Subject(id: "biology", title: "Биология"),
        Subject(id: "computer-science", title: "Информатика"),
        Subject(id: "history", title: "История"),
        Subject(id: "math", title: "Математика"),
        Subject(id: "russian", title: "Русский язык"),
        Subject(id: "physics", title: "Физика"),
        Subject(id: "chemistry", title: "Химия")
    ]
}

enum ExamCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case ege = "EGE"
    case oge = "OGE"
    case vpr = "VPR"
    case constructor = "Constructor"

    var id: String { rawValue }
}
