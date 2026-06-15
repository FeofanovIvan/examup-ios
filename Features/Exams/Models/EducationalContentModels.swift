import Foundation

struct EducationalContentDatabase: Codable, Equatable {
    let datasetID: String
    let title: String
    let subject: Subject
    let examCategory: ExamCategory
    let level: String?
    let version: Int
    let source: String?
    let blocks: [EducationalContentBlock]
    let tasks: [EducationalTask]
}

struct EducationalContentBlock: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subjectID: Subject.ID
    let examCategory: ExamCategory
    let taskIDs: [EducationalTask.ID]
}

struct EducationalTask: Identifiable, Codable, Equatable {
    let id: String
    let questionNumber: String?
    let topic: String
    let questionHTML: String
    let drawingURL: String?
    let explanationDrawingURL: String?
    let answerDrawingURL: String?
    let audioURL: String?
    let answerType: String?
    let answer: String
    let difficulty: String?
    let resourceID: String?
    let explanationHTML: String?
    let subjectID: Subject.ID
    let examCategory: ExamCategory
    let level: String?
    let blockID: EducationalContentBlock.ID
}

struct EducationalContentSummary: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subject: Subject
    let examCategory: ExamCategory
    let level: String?
    let version: Int
    let taskCount: Int
}
