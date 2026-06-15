import Foundation

enum AuthRoute: Hashable {
    case welcome
    case login
    case register
    case emailVerification
    case initialSetup
}

enum HomeRoute: Hashable {
    case subject(String)
    case subjectLibraries
    case notifications
    case examCategory(ExamCategory)
    case examConsent(ExamStartContext)
    case examDataset(String, ExamProctoringConsent?)
    case examConstructor(String)
    case customExamConsent(ExamConstructorStartContext)
    case customExam(ExamConstructorStartContext, ExamProctoringConsent?)
}

struct ExamStartContext: Hashable {
    let title: String
    let category: ExamCategory
    let datasetID: String?
}

enum TutorsRoute: Hashable {
    case assignmentConsent(ExamConstructorStartContext)
    case assignmentExam(ExamConstructorStartContext, ExamProctoringConsent)
    case notifications
}

enum CalendarRoute: Hashable {
    case day(Date)
}

enum SettingsRoute: Hashable {
    case profile
    case security
    case notifications
    case subjects
    case examSettings
    case deadlines
    case support
    case about
}

enum TeacherSettingsRoute: Hashable {
    case profile
    case security
    case notifications
    case examSettings
    case deadlines
    case support
    case about
}

extension SettingsRoute {
    init?(rowID: String) {
        switch rowID {
        case "profile":       self = .profile
        case "security":      self = .security
        case "notifications": self = .notifications
        case "subjects":      self = .subjects
        case "exam-settings": self = .examSettings
        case "deadlines":     self = .deadlines
        case "support":       self = .support
        case "about":         self = .about
        default: return nil
        }
    }
}
