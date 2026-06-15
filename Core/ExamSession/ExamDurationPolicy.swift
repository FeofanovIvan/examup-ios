import Foundation

enum ExamDurationPolicy {
    static func durationSeconds(
        datasetID: String,
        subjectID: String,
        kind: ExamSessionKind,
        customDurationSeconds: Int?
    ) -> Int {
        if let customDurationSeconds {
            return customDurationSeconds
        }

        let minutes: Int
        switch kind {
        case .ege:
            minutes = egeMinutes(datasetID: datasetID, subjectID: subjectID)
        case .oge:
            minutes = ogeMinutes(subjectID: subjectID)
        case .vpr:
            minutes = 45
        case .constructor:
            minutes = 150
        }
        return minutes * 60
    }

    private static func egeMinutes(datasetID: String, subjectID: String) -> Int {
        if datasetID == SeedDatasetID.mathEGEBase.rawValue {
            return 180
        }
        if datasetID == SeedDatasetID.mathEGEProfile.rawValue {
            return 235
        }

        switch subjectID {
        case "russian", "history":
            return 210
        default:
            return 210
        }
    }

    private static func ogeMinutes(subjectID: String) -> Int {
        switch subjectID {
        case "math", "russian":
            return 235
        case "history":
            return 180
        default:
            return 180
        }
    }
}
