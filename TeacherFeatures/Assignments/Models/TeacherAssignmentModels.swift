import Foundation

enum TeacherAssignmentItemKind: String, Codable, Equatable {
    case seed
    case custom
}

struct TeacherAssignmentSeedItem: Identifiable, Equatable {
    let id: String
    let datasetID: String
    let task: EducationalTask

    var title: String {
        "№ \(task.questionNumber ?? "?")"
    }

    var subtitle: String {
        task.topic
    }
}

struct TeacherAssignmentQuestionGroup: Identifiable, Equatable {
    let id: String
    let questionNumber: String
    let topic: String
    let tasks: [EducationalTask]

    var title: String {
        "№ \(questionNumber)"
    }

    var subtitle: String {
        topic
    }
}

struct TeacherCustomAssignmentDraft: Equatable {
    var taskText = ""
    var answerText = ""
    var explanationText = ""
    var attachment: TeacherAssignmentAttachmentDraft?

    var trimmedTaskText: String {
        taskText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAnswerText: String {
        answerText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedExplanationText: String {
        explanationText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedTaskText.isEmpty && !trimmedAnswerText.isEmpty
    }
}

struct TeacherAssignmentAttachmentDraft: Equatable {
    let data: Data
    let filename: String
    let contentType: String
    let originalBytes: Int

    var storedBytes: Int {
        data.count
    }
}

struct TeacherAssignmentCustomItem: Identifiable, Equatable {
    let id: String
    let taskText: String
    let answerText: String
    let explanationText: String?
    let attachment: TeacherAssignmentAttachment?
}

struct TeacherAssignmentAttachment: Equatable, Codable {
    let url: String
    let storagePath: String
    let filename: String
    let contentType: String
    let originalBytes: Int
    let storedBytes: Int

    var isImage: Bool {
        contentType.hasPrefix("image/")
    }
}

struct TeacherAssignmentPublishDraft: Equatable {
    var title: String
    var studentIDsText: String
    var durationSeconds: Int = 2 * 60 * 60 + 30 * 60
    var questionCount: Int = 20
    var dueAt: Date = Date().addingTimeInterval(24 * 60 * 60)

    var studentIDs: [String] {
        studentIDsText
            .split { $0 == "," || $0 == "\n" || $0 == " " || $0 == "\t" }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct TeacherAssignmentPayload: Equatable {
    let id: String
    let teacherPublicID: String
    let title: String
    let studentIDs: [String]
    let durationSeconds: Int
    let questionCount: Int
    let dueAt: Date
    let seedItems: [TeacherAssignmentSeedItem]
    let customItems: [TeacherAssignmentCustomItem]
}
