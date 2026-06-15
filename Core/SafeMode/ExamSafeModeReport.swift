import Foundation

// MARK: - Report

struct ExamSafeModeReport: Identifiable, Codable, Equatable {
    let id: String              // == sessionID
    let sessionID: String
    let generatedAt: Date
    let score: Int              // 0 (чисто) – 100 (списывает)
    let verdict: ExamSafeModeVerdict
    let summary: String         // краткий текст на русском
    let totalCaptureCount: Int?
    let captureFindingsCount: Int
    let transcriptFindingsCount: Int
    let flags: [ExamSafeModeFlag]
}

// MARK: - Verdict

enum ExamSafeModeVerdict: String, Codable, Equatable {
    case clean       = "clean"       // 0–25
    case suspicious  = "suspicious"  // 26–60
    case cheating    = "cheating"    // 61–100

    var localizedTitle: String {
        switch self {
        case .clean:      return "Нарушений не выявлено"
        case .suspicious: return "Подозрительное поведение"
        case .cheating:   return "Признаки списывания"
        }
    }
}

// MARK: - Flags

enum ExamSafeModeFlag: String, Codable, Equatable, CaseIterable {
    case captureUnavailable = "capture_unavailable"
    case absent        = "absent"         // ученик уходил из кадра
    case multipleFaces = "multiple_faces" // в кадре появлялись посторонние
    case gazeAway      = "gaze_away"      // взгляд отведён от экрана
    case speechDetected = "speech"        // обнаружена речь
    case suspiciousKeywords = "keywords"  // подозрительные фразы
}

// MARK: - Extended per-capture findings (stored in archive)

struct ExamSafeModeCaptureFinding: Identifiable, Codable, Equatable {
    let id: String              // == ExamSafeModeCapture.id
    let captureIndex: Int
    let capturedAt: Date
    let faceCount: Int
    let userPresence: ExamSafeModeUserPresence
    let gazeStatus: ExamSafeModeGazeStatus
    var anomaly: Bool {
        userPresence == .absent || userPresence == .multipleFaces || gazeStatus == .lookingAway
    }
}

// MARK: - Transcript findings

struct ExamSafeModeTranscriptFinding: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let keyword: String?
    let capturedAt: Date
}
