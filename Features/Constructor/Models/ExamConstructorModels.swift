import Foundation

struct ExamConstructorDatasetOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: ExamCategory
    let datasetID: String
}

struct ExamConstructorQuestionOption: Identifiable, Hashable {
    let id: String
    let taskID: EducationalTask.ID
    let questionNumber: String
    let topic: String

    var title: String {
        "№ \(questionNumber)"
    }

    var subtitle: String {
        topic
    }
}

struct ExamConstructorStartContext: Hashable {
    let datasetID: String
    let title: String
    let taskIDs: [EducationalTask.ID]
    let durationSeconds: Int
    var assignmentID: String? = nil
}
