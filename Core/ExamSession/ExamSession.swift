import Foundation

struct ExamSession: Identifiable, Codable, Equatable {
    let id: String
    let examID: String
    let datasetID: String
    let subjectID: String
    let subjectTitle: String
    let kind: ExamSessionKind
    var taskIDs: [EducationalTask.ID]
    var answers: [EducationalTask.ID: String]
    var status: ExamSessionStatus
    var durationSeconds: Int
    var startedAt: Date
    var updatedAt: Date
    var submittedAt: Date?
    var interruptedAt: Date?
    var timeExpiredAt: Date?
    var actualDurationSeconds: Int?
    var safeModeEnabled: Bool
    var safeSessionValid: Bool
    var syncState: SyncState
    var proctoringConsent: ExamProctoringConsent?

    init(
        id: String = UUID().uuidString,
        examID: String,
        datasetID: String,
        subjectID: String,
        subjectTitle: String = "",
        kind: ExamSessionKind = .ege,
        taskIDs: [EducationalTask.ID] = [],
        answers: [EducationalTask.ID: String] = [:],
        status: ExamSessionStatus = .started,
        durationSeconds: Int = 3_600,
        startedAt: Date = Date(),
        updatedAt: Date = Date(),
        submittedAt: Date? = nil,
        interruptedAt: Date? = nil,
        timeExpiredAt: Date? = nil,
        actualDurationSeconds: Int? = nil,
        safeModeEnabled: Bool = false,
        safeSessionValid: Bool = false,
        syncState: SyncState = .idle,
        proctoringConsent: ExamProctoringConsent? = nil
    ) {
        self.id = id
        self.examID = examID
        self.datasetID = datasetID
        self.subjectID = subjectID
        self.subjectTitle = subjectTitle
        self.kind = kind
        self.taskIDs = taskIDs
        self.answers = answers
        self.status = status
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.submittedAt = submittedAt
        self.interruptedAt = interruptedAt
        self.timeExpiredAt = timeExpiredAt
        self.actualDurationSeconds = actualDurationSeconds
        self.safeModeEnabled = safeModeEnabled
        self.safeSessionValid = safeSessionValid
        self.syncState = syncState
        self.proctoringConsent = proctoringConsent
    }
}

enum ExamSessionKind: String, Codable, Equatable {
    case ege
    case oge
    case vpr
    case constructor

    var title: String {
        switch self {
        case .ege: return "ЕГЭ"
        case .oge: return "ОГЭ"
        case .vpr: return "ВПР"
        case .constructor: return "Конструктор"
        }
    }
}

struct ExamProctoringConsent: Codable, Equatable, Hashable {
    let allowsCamera: Bool
    let allowsMicrophone: Bool
    let acceptedAgreement: Bool
    let confirmedAt: Date

    static func accepted(at date: Date = Date()) -> ExamProctoringConsent {
        ExamProctoringConsent(
            allowsCamera: true,
            allowsMicrophone: true,
            acceptedAgreement: true,
            confirmedAt: date
        )
    }

    static func declined(at date: Date = Date()) -> ExamProctoringConsent {
        ExamProctoringConsent(
            allowsCamera: false,
            allowsMicrophone: false,
            acceptedAgreement: false,
            confirmedAt: date
        )
    }
}

enum ExamSessionStatus: String, Codable, Equatable {
    case started
    case inProgress = "in_progress"
    case interrupted
    case cancelled
    case submitted
    case syncPending = "sync_pending"

    var isActive: Bool {
        switch self {
        case .started, .inProgress, .interrupted, .syncPending:
            return true
        case .cancelled, .submitted:
            return false
        }
    }
}
