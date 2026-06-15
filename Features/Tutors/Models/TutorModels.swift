import Foundation

struct TutorConnection: Identifiable, Codable, Equatable {
    let id: String
    let tutorID: String
    let tutorUid: String
    let name: String
    let email: String
    let subject: Subject
    let totalAssignments: Int
    let completedAssignments: Int
    let pendingNotifications: Int
}

struct TutorAssignment: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subject: Subject
    let tutorEmail: String
    let dueTitle: String
    let remainingTitle: String
    let durationSeconds: Int
    let variantVersionID: String
    let isSubmitted: Bool
}

struct TutorFilters: Codable, Equatable {
    var subjectID: String?
}

struct AddTutorRequest: Codable, Equatable {
    let tutorID: String
    let email: String
    let subject: Subject
}
