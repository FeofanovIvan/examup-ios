import PDFKit
import UIKit

/// Generates a tamper-evident PDF report from an ExamSafeModeReport + archive.
enum ExamSafeModePDFExporter {

    static func export(report: ExamSafeModeReport, archive: ExamSafeModeArchive) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 at 72 dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            // Page 1: Header + Summary + Score
            context.beginPage()
            var cursor: CGFloat = 40
            cursor = drawHeader(in: pageRect, cursor: cursor, report: report, archive: archive)
            cursor = drawSummarySection(in: pageRect, cursor: cursor, report: report)
            cursor = drawScoreGauge(in: pageRect, cursor: cursor, report: report)
            cursor = drawFlags(in: pageRect, cursor: cursor, report: report)

            // Page 2: Photo evidence
            if !archive.captures.isEmpty {
                context.beginPage()
                cursor = 40
                cursor = drawSectionTitle("Снимки экрана", rect: pageRect, cursor: cursor)
                cursor = drawPhotoGrid(in: pageRect, cursor: cursor, captures: archive.captures, folderURL: archive.folderURL, context: context)
            }

            // Page 3: Transcript
            let finalSegments = archive.transcriptSegments.filter(\.isFinal)
            if !finalSegments.isEmpty {
                context.beginPage()
                cursor = 40
                cursor = drawSectionTitle("Транскрипция аудио", rect: pageRect, cursor: cursor)
                cursor = drawTranscript(
                    in: pageRect,
                    cursor: cursor,
                    segments: finalSegments,
                    report: report,
                    context: context
                )
            }

            // Final page: hash footer (always on last page as extra guarantee)
            drawFooter(in: pageRect, report: report, archive: archive)
        }
    }

    // MARK: - Drawing helpers

    @discardableResult
    private static func drawHeader(
        in rect: CGRect, cursor: CGFloat,
        report: ExamSafeModeReport, archive: ExamSafeModeArchive
    ) -> CGFloat {
        let margin: CGFloat = 40
        let width = rect.width - margin * 2

        // App name
        let appAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .black),
            .foregroundColor: UIColor(red: 0.44, green: 0.34, blue: 0.96, alpha: 1)
        ]
        "ExamUp".draw(at: CGPoint(x: margin, y: cursor), withAttributes: appAttrs)

        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let subtitle = "Отчёт антиплагиата · \(iso(report.generatedAt))"
        subtitle.draw(at: CGPoint(x: margin, y: cursor + 28), withAttributes: subtitleAttrs)

        // Separator
        let sepY = cursor + 54
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: sepY))
        path.addLine(to: CGPoint(x: margin + width, y: sepY))
        UIColor(red: 0.9, green: 0.88, blue: 1, alpha: 1).setStroke()
        path.lineWidth = 1
        path.stroke()

        return sepY + 16
    }

    @discardableResult
    private static func drawSummarySection(
        in rect: CGRect, cursor: CGFloat, report: ExamSafeModeReport
    ) -> CGFloat {
        let margin: CGFloat = 40
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.darkText
        ]
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.darkText
        ]
        "Заключение".draw(at: CGPoint(x: margin, y: cursor), withAttributes: titleAttrs)
        let summaryRect = CGRect(x: margin, y: cursor + 22, width: rect.width - margin * 2, height: 200)
        report.summary.draw(in: summaryRect, withAttributes: bodyAttrs)

        // Calculate actual height used by summary text
        let boundingRect = report.summary.boundingRect(
            with: CGSize(width: summaryRect.width, height: 200),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: bodyAttrs,
            context: nil
        )
        return cursor + 22 + boundingRect.height + 20
    }

    @discardableResult
    private static func drawScoreGauge(in rect: CGRect, cursor: CGFloat, report: ExamSafeModeReport) -> CGFloat {
        let margin: CGFloat = 40
        let trackWidth = rect.width - margin * 2
        let trackHeight: CGFloat = 14
        let trackY = cursor + 20

        // Background track
        let trackRect = CGRect(x: margin, y: trackY, width: trackWidth, height: trackHeight)
        let trackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: 7)
        UIColor(red: 0.93, green: 0.93, blue: 0.97, alpha: 1).setFill()
        trackPath.fill()

        // Fill
        let fillWidth = trackWidth * CGFloat(report.score) / 100.0
        if fillWidth > 0 {
            let fillRect = CGRect(x: margin, y: trackY, width: fillWidth, height: trackHeight)
            let fillPath = UIBezierPath(roundedRect: fillRect, cornerRadius: 7)
            verdictColor(report.verdict).setFill()
            fillPath.fill()
        }

        // Labels
        let scoreLabel = "\(report.score)%  —  \(report.verdict.localizedTitle)"
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: verdictColor(report.verdict)
        ]
        scoreLabel.draw(at: CGPoint(x: margin, y: cursor), withAttributes: scoreAttrs)

        let axisAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ]
        "0".draw(at: CGPoint(x: margin, y: trackY + trackHeight + 4), withAttributes: axisAttrs)
        "100".draw(at: CGPoint(x: margin + trackWidth - 20, y: trackY + trackHeight + 4), withAttributes: axisAttrs)

        return trackY + trackHeight + 22
    }

    @discardableResult
    private static func drawFlags(in rect: CGRect, cursor: CGFloat, report: ExamSafeModeReport) -> CGFloat {
        guard !report.flags.isEmpty else { return cursor }
        let margin: CGFloat = 40
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.darkText
        ]
        let flagAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 1)
        ]
        "Нарушения:".draw(at: CGPoint(x: margin, y: cursor), withAttributes: titleAttrs)
        var y = cursor + 18
        for flag in report.flags {
            "• \(flag.localizedDescription)".draw(at: CGPoint(x: margin + 8, y: y), withAttributes: flagAttrs)
            y += 16
        }
        return y + 10
    }

    @discardableResult
    private static func drawSectionTitle(_ title: String, rect: CGRect, cursor: CGFloat) -> CGFloat {
        let margin: CGFloat = 40
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.darkText
        ]
        title.draw(at: CGPoint(x: margin, y: cursor), withAttributes: attrs)
        return cursor + 28
    }

    @discardableResult
    private static func drawPhotoGrid(
        in rect: CGRect, cursor: CGFloat,
        captures: [ExamSafeModeCapture],
        folderURL: URL,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let margin: CGFloat = 40
        let columns: CGFloat = 4
        let spacing: CGFloat = 8
        let availableWidth = rect.width - margin * 2
        let cellWidth = (availableWidth - spacing * (columns - 1)) / columns
        let cellHeight = cellWidth * 0.75

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7),
            .foregroundColor: UIColor.darkGray
        ]
        let anomalyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .bold),
            .foregroundColor: UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 1)
        ]

        var y = cursor
        var col: CGFloat = 0

        for capture in captures {
            let x = margin + col * (cellWidth + spacing)

            // Draw image
            let imageURL = folderURL.appendingPathComponent(capture.filename)
            if let imageData = try? Data(contentsOf: imageURL),
               let uiImage = UIImage(data: imageData) {
                let imageRect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
                uiImage.draw(in: imageRect)

                // Border for anomalies
                if capture.userPresence != .present || capture.gazeStatus == .lookingAway {
                    let borderPath = UIBezierPath(rect: imageRect)
                    UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 0.6).setStroke()
                    borderPath.lineWidth = 1.5
                    borderPath.stroke()
                }
            } else {
                // Placeholder
                let placeholderRect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
                UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1).setFill()
                UIBezierPath(rect: placeholderRect).fill()
            }

            // Caption
            let caption = "#\(capture.index) \(shortTime(capture.capturedAt))"
            caption.draw(at: CGPoint(x: x, y: y + cellHeight + 2), withAttributes: labelAttrs)

            let anomalyLabel = anomalyDescription(capture)
            if !anomalyLabel.isEmpty {
                anomalyLabel.draw(at: CGPoint(x: x, y: y + cellHeight + 11), withAttributes: anomalyAttrs)
            }

            col += 1
            if col >= columns {
                col = 0
                y += cellHeight + 28

                // Page break if needed
                if y + cellHeight > rect.height - 60 {
                    context.beginPage()
                    y = 40
                }
            }
        }
        if col > 0 { y += cellHeight + 28 }
        return y
    }

    @discardableResult
    private static func drawTranscript(
        in rect: CGRect, cursor: CGFloat,
        segments: [ExamSafeModeTranscriptSegment],
        report: ExamSafeModeReport,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let margin: CGFloat = 40
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkText
        ]
        let flaggedAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 1)
        ]
        let suspiciousKeywords = ["подскажи", "подскажите", "помоги", "помогите",
                                  "какой ответ", "скажи ответ", "как решить", "напиши мне",
                                  "списать", "списываю", "спишу"]

        var y = cursor
        for segment in segments {
            let isSuspicious = suspiciousKeywords.contains { segment.text.lowercased().contains($0) }
            let attrs = isSuspicious ? flaggedAttrs : normalAttrs
            let line = "[\(shortTime(segment.capturedAt))] \(segment.text)"
            let availableWidth = rect.width - margin * 2
            let bounded = line.boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs,
                context: nil
            )
            if y + bounded.height > rect.height - 60 {
                context.beginPage()
                y = 40
            }
            let lineRect = CGRect(x: margin, y: y, width: availableWidth, height: bounded.height + 2)
            line.draw(in: lineRect, withAttributes: attrs)
            y += bounded.height + 4
        }
        return y
    }

    private static func drawFooter(in rect: CGRect, report: ExamSafeModeReport, archive: ExamSafeModeArchive) {
        let margin: CGFloat = 40
        let y = rect.height - 36
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.lightGray
        ]
        let hashSummary = archive.fileHashes.sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value.prefix(12))..." }
            .joined(separator: "  |  ")
        let footerText = "SHA-256: \(hashSummary)  |  Сгенерировано: \(iso(report.generatedAt))"
        footerText.draw(in: CGRect(x: margin, y: y, width: rect.width - margin * 2, height: 24), withAttributes: footerAttrs)
    }

    // MARK: - Utility

    private static func verdictColor(_ verdict: ExamSafeModeVerdict) -> UIColor {
        switch verdict {
        case .clean:      return UIColor(red: 0.13, green: 0.66, blue: 0.35, alpha: 1)
        case .suspicious: return UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1)
        case .cheating:   return UIColor(red: 0.85, green: 0.26, blue: 0.21, alpha: 1)
        }
    }

    private static func anomalyDescription(_ c: ExamSafeModeCapture) -> String {
        switch c.userPresence {
        case .absent:        return "нет в кадре"
        case .multipleFaces: return "посторонние"
        case .present:       return c.gazeStatus == .lookingAway ? "взгляд в сторону" : ""
        case .notEvaluated:  return ""
        }
    }

    private static func shortTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }

    private static func iso(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.string(from: date)
    }
}

// MARK: - Flag localisation

private extension ExamSafeModeFlag {
    var localizedDescription: String {
        switch self {
        case .captureUnavailable:   return "Камера или запись кадра недоступна"
        case .absent:              return "Ученик покидал кадр"
        case .multipleFaces:       return "В кадре появлялись посторонние"
        case .gazeAway:            return "Взгляд отведён от экрана"
        case .speechDetected:      return "Обнаружена речь во время экзамена"
        case .suspiciousKeywords:  return "Подозрительные фразы в аудио"
        }
    }
}
