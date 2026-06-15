import Foundation

struct ExamSafeModeConfiguration: Equatable {
    let sessionID: ExamSession.ID
    let durationSeconds: Int
    let maxCaptures: Int
    let recordsCamera: Bool
    let recordsMicrophone: Bool

    init(
        sessionID: ExamSession.ID,
        durationSeconds: Int,
        maxCaptures: Int = 20,
        recordsCamera: Bool = true,
        recordsMicrophone: Bool = true
    ) {
        self.sessionID = sessionID
        self.durationSeconds = durationSeconds
        self.maxCaptures = max(1, min(maxCaptures, 20))
        self.recordsCamera = recordsCamera
        self.recordsMicrophone = recordsMicrophone
    }
}

struct ExamSafeModeArchive: Identifiable, Codable, Equatable {
    let id: String
    let sessionID: ExamSession.ID
    let folderURL: URL
    var captures: [ExamSafeModeCapture]
    var transcriptSegments: [ExamSafeModeTranscriptSegment]
    var startedAt: Date
    var finishedAt: Date?
    /// SHA-256 hex digest per filename (populated by archiveStore)
    var fileHashes: [String: String]
}

struct ExamSafeModeCapture: Identifiable, Codable, Equatable {
    let id: String
    let index: Int
    let filename: String
    let capturedAt: Date
    let scheduledOffsetSeconds: Int
    let quality: String
    /// -1 = not evaluated, 0 = no face, 1 = one face, 2+ = multiple
    var faceCount: Int
    var userPresence: ExamSafeModeUserPresence
    var gazeStatus: ExamSafeModeGazeStatus
}

enum ExamSafeModeUserPresence: String, Codable, Equatable {
    case notEvaluated  = "not_evaluated"
    case present
    case absent
    case multipleFaces = "multiple_faces"
}

enum ExamSafeModeGazeStatus: String, Codable, Equatable {
    case notEvaluated = "not_evaluated"
    case lookingAtScreen = "looking_at_screen"
    case lookingAway = "looking_away"
}

struct ExamSafeModeTranscriptSegment: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let capturedAt: Date
    let localeIdentifier: String
    let isFinal: Bool
}
