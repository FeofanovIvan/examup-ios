import Foundation
import Vision

// MARK: - Analyzer

/// Analyses a finished archive using Apple Vision (face detection + gaze) and
/// keyword-based transcript scanning. No AI or network calls required.
enum ExamSafeModeAnalyzer {

    // MARK: Face analysis

    struct FaceAnalysisResult {
        let faceCount: Int
        let userPresence: ExamSafeModeUserPresence
        let gazeStatus: ExamSafeModeGazeStatus
    }

    /// Synchronously analyses a JPEG frame using Vision. Call off the main thread.
    static func analyzeFaces(in jpegData: Data) -> FaceAnalysisResult {
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3

        let handler = VNImageRequestHandler(data: jpegData, options: [:])
        try? handler.perform([request])

        let faces = request.results ?? []
        let faceCount = faces.count

        guard faceCount > 0 else {
            return FaceAnalysisResult(faceCount: 0, userPresence: .absent, gazeStatus: .notEvaluated)
        }

        if faceCount > 1 {
            return FaceAnalysisResult(faceCount: faceCount, userPresence: .multipleFaces, gazeStatus: .notEvaluated)
        }

        // Single face — estimate gaze via yaw (left/right head rotation)
        // |yaw| > 0.52 rad (~30°) means head is significantly turned away from screen
        let gazeStatus: ExamSafeModeGazeStatus
        if let yaw = faces[0].yaw {
            gazeStatus = abs(yaw.doubleValue) > 0.52 ? .lookingAway : .lookingAtScreen
        } else {
            gazeStatus = .notEvaluated
        }

        return FaceAnalysisResult(faceCount: 1, userPresence: .present, gazeStatus: gazeStatus)
    }

    // MARK: Post-exam report

    static func buildReport(from archive: ExamSafeModeArchive) -> ExamSafeModeReport {
        let captureFindingScore = captureScore(archive.captures)
        let (transcriptScore, transcriptFindingCount, flags) = transcriptScore(archive.transcriptSegments)

        // Merge capture flags
        var allFlags = flags
        if archive.captures.isEmpty { allFlags.insert(.captureUnavailable) }
        let presences = Set(archive.captures.map(\.userPresence))
        if presences.contains(.absent)        { allFlags.insert(.absent) }
        if presences.contains(.multipleFaces) { allFlags.insert(.multipleFaces) }
        let gazes = Set(archive.captures.map(\.gazeStatus))
        if gazes.contains(.lookingAway)       { allFlags.insert(.gazeAway) }

        let missingCaptureScore = archive.captures.isEmpty ? 30 : 0
        let totalScore = min(100, captureFindingScore + transcriptScore + missingCaptureScore)
        let verdict = verdict(for: totalScore)
        let summary = buildSummary(
            score: totalScore,
            verdict: verdict,
            flags: allFlags,
            totalCaptures: archive.captures.count,
            captureAnomalyCount: archive.captures.filter { captureIsAnomaly($0) }.count,
            transcriptFindingCount: transcriptFindingCount
        )

        return ExamSafeModeReport(
            id: archive.sessionID,
            sessionID: archive.sessionID,
            generatedAt: Date(),
            score: totalScore,
            verdict: verdict,
            summary: summary,
            totalCaptureCount: archive.captures.count,
            captureFindingsCount: archive.captures.filter { captureIsAnomaly($0) }.count,
            transcriptFindingsCount: transcriptFindingCount,
            flags: Array(allFlags)
        )
    }

    // MARK: - Private helpers

    private static func captureIsAnomaly(_ c: ExamSafeModeCapture) -> Bool {
        c.userPresence == .absent || c.userPresence == .multipleFaces || c.gazeStatus == .lookingAway
    }

    private static func captureScore(_ captures: [ExamSafeModeCapture]) -> Int {
        guard !captures.isEmpty else { return 0 }
        var raw = 0.0
        for c in captures {
            switch c.userPresence {
            case .absent:        raw += 3.0
            case .multipleFaces: raw += 2.5
            case .present:
                if c.gazeStatus == .lookingAway { raw += 1.5 }
            case .notEvaluated:  break
            }
        }
        // Normalise: if every capture were absent that would be 3*n → max 3*n → scale to 70 pts
        let maxPossible = Double(captures.count) * 3.0
        let normalised = (raw / maxPossible) * 70.0
        return min(70, Int(normalised.rounded()))
    }

    private static func transcriptScore(_ segments: [ExamSafeModeTranscriptSegment]) -> (score: Int, findingCount: Int, flags: Set<ExamSafeModeFlag>) {
        let finalSegments = segments.filter(\.isFinal)
        var flags = Set<ExamSafeModeFlag>()
        var score = 0
        var findingCount = 0

        if !finalSegments.isEmpty {
            flags.insert(.speechDetected)
            // Any speech: +5 pts (students shouldn't speak during written exams)
            score += min(5, finalSegments.count * 2)
            findingCount += finalSegments.count
        }

        let allText = finalSegments.map(\.text).joined(separator: " ").lowercased()
        var keywordHits = 0
        for keyword in suspiciousKeywords where allText.contains(keyword) {
            keywordHits += 1
        }
        if keywordHits > 0 {
            flags.insert(.suspiciousKeywords)
            score += min(25, keywordHits * 6)
            findingCount += keywordHits
        }

        return (min(30, score), findingCount, flags)
    }

    private static func verdict(for score: Int) -> ExamSafeModeVerdict {
        switch score {
        case 0...25:   return .clean
        case 26...60:  return .suspicious
        default:       return .cheating
        }
    }

    private static func buildSummary(
        score: Int,
        verdict: ExamSafeModeVerdict,
        flags: Set<ExamSafeModeFlag>,
        totalCaptures: Int,
        captureAnomalyCount: Int,
        transcriptFindingCount: Int
    ) -> String {
        var parts: [String] = []

        switch verdict {
        case .clean:
            parts.append("Анализ не выявил признаков списывания.")
        case .suspicious:
            parts.append("Обнаружено подозрительное поведение (счёт \(score)/100).")
        case .cheating:
            parts.append("Зафиксированы явные признаки списывания (счёт \(score)/100).")
        }

        if totalCaptures > 0 {
            if captureAnomalyCount == 0 {
                parts.append("Все \(totalCaptures) снимков в норме.")
            } else {
                parts.append("На \(captureAnomalyCount) из \(totalCaptures) снимков выявлены нарушения.")
            }
        } else {
            parts.append("Снимки безопасного режима отсутствуют.")
        }

        var flagParts: [String] = []
        if flags.contains(.captureUnavailable) { flagParts.append("камера или запись кадра недоступна") }
        if flags.contains(.absent)          { flagParts.append("ученик покидал кадр") }
        if flags.contains(.multipleFaces)   { flagParts.append("в кадре появлялись посторонние") }
        if flags.contains(.gazeAway)        { flagParts.append("взгляд отведён от экрана") }
        if flags.contains(.speechDetected)  { flagParts.append("обнаружена речь") }
        if flags.contains(.suspiciousKeywords) { flagParts.append("подозрительные фразы в аудио") }

        if !flagParts.isEmpty {
            parts.append("Выявлено: \(flagParts.joined(separator: ", ")).")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Suspicious keywords

    private static let suspiciousKeywords: [String] = [
        "подскажи", "подскажите", "помоги", "помогите",
        "какой ответ", "скажи ответ", "как решить", "напиши мне",
        "подсмотрю", "списать", "списываю", "спишу",
        "смотри сюда", "покажи", "дай списать", "можно списать",
        "решение", "правильный ответ"
    ]
}
