import Foundation

struct Exam: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subjectID: String
    let category: ExamCategory
}
