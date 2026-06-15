import Foundation

enum ExamContentRendering {
    static func unifiedHTML(primaryHTML: String, drawingURL: String?) -> String {
        let normalizedHTML = primaryHTML
            .removingDuplicateDrawingImagesBeforeInlineSVG
            .removingDuplicateEmbeddedImages
        guard !normalizedHTML.containsEmbeddedVisual else {
            return normalizedHTML
        }

        let drawings = drawingURL?.examDrawingParts ?? []
        guard !drawings.isEmpty else {
            return normalizedHTML
        }
        return normalizedHTML + "\n" + drawingContent(from: drawings)
    }

    static func drawingContent(from drawings: [String]) -> String {
        if drawings.count == 1,
           let drawing = drawings.first,
           drawing.containsInlineHTML {
            return drawing
        }

        return drawings
            .map { drawing in
                drawing.renderableExamDrawingHTML
            }
            .joined(separator: "\n")
    }
}

extension String {
    var trimmedExamHTML: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == "$$$" ? "" : trimmed
    }

    var renderableExamExplanationHTML: String {
        trimmedExamHTML.replacingOccurrences(
            of: #"display\s*:\s*none\s*;?"#,
            with: "display:block;",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    var examDrawingParts: [String] {
        let trimmed = trimmedExamHTML
        if trimmed.containsInlineHTML {
            return [trimmed]
        }
        return trimmed
            .split(separator: ";")
            .map { String($0).trimmedExamHTML }
            .filter { !$0.isEmpty }
    }

    var normalizedSeedImagePath: String {
        let trimmed = trimmedExamHTML
        if trimmed.hasPrefix("SeedData/")
            || trimmed.hasPrefix("/")
            || trimmed.localizedCaseInsensitiveContains("://")
            || trimmed.hasPrefix("data:") {
            return trimmed
        }
        return trimmed
    }

    var containsInlineHTML: Bool {
        localizedCaseInsensitiveContains("<img")
            || localizedCaseInsensitiveContains("<svg")
            || localizedCaseInsensitiveContains("<html")
            || localizedCaseInsensitiveContains("<canvas")
            || localizedCaseInsensitiveContains("<script")
            || localizedCaseInsensitiveContains("<div")
    }

    var isImageResourcePath: Bool {
        let lowercasedValue = trimmedExamHTML.lowercased()
        return lowercasedValue.hasSuffix(".png")
            || lowercasedValue.hasSuffix(".jpg")
            || lowercasedValue.hasSuffix(".jpeg")
            || lowercasedValue.hasSuffix(".webp")
            || lowercasedValue.hasSuffix(".gif")
            || lowercasedValue.hasSuffix(".svg")
            || lowercasedValue.hasPrefix("data:image")
    }

    var isAudioResourcePath: Bool {
        let lowercasedValue = trimmedExamHTML.lowercased()
        return lowercasedValue.hasSuffix(".mp3")
            || lowercasedValue.hasSuffix(".m4a")
            || lowercasedValue.hasSuffix(".wav")
            || lowercasedValue.hasSuffix(".ogg")
    }

    var renderableExamDrawingHTML: String {
        let trimmed = trimmedExamHTML
        if trimmed.containsInlineHTML {
            return trimmed
        }
        if trimmed.isImageResourcePath {
            let imagePath = trimmed.normalizedSeedImagePath
            return """
            <figure class="exam-drawing">
                <img src="\(imagePath.escapedHTMLAttribute)" alt="Иллюстрация к заданию">
            </figure>
            """
        }
        if trimmed.isAudioResourcePath {
            return ""
        }
        return """
        <figure class="exam-drawing">
            \(trimmed)
        </figure>
        """
    }

    var escapedHTMLAttribute: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    var escapedLatexText: String {
        replacingOccurrences(of: "\\", with: "\\textbackslash{}")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
    }

    var firstAudioSourcePath: String? {
        let pattern = #"<source[^>]+src\s*=\s*["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range),
              match.numberOfRanges > 1,
              let sourceRange = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[sourceRange]).removingPercentEncoding ?? String(self[sourceRange])
    }

    var removingEmbeddedAudioControls: String {
        let patterns = [
            #"(?is)<p>\s*<!--np-->.*?<audio.*?</audio>\s*<!--np-->\s*</p>"#,
            #"(?is)<audio.*?</audio>"#
        ]
        return patterns.reduce(self) { result, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return result
            }
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            return regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
    }

    var embeddedImageCount: Int {
        let pattern = #"(?is)<img\b[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return regex.numberOfMatches(
            in: self,
            range: NSRange(startIndex..<endIndex, in: self)
        )
    }

    var removingEmbeddedImages: String {
        let pattern = #"(?is)<img\b[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        return regex.stringByReplacingMatches(
            in: self,
            range: NSRange(startIndex..<endIndex, in: self),
            withTemplate: ""
        )
    }

    var containsEmbeddedVisual: Bool {
        localizedCaseInsensitiveContains("<img")
            || localizedCaseInsensitiveContains("<svg")
            || localizedCaseInsensitiveContains("<canvas")
    }

    var removingDuplicateDrawingImagesBeforeInlineSVG: String {
        guard localizedCaseInsensitiveContains("<svg") else { return self }
        let pattern = #"(?is)<img\b[^>]*(?:class\s*=\s*["'][^"']*\bdrawing\b[^"']*["']|data-drawing-id\s*=)[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        return regex.stringByReplacingMatches(
            in: self,
            range: NSRange(startIndex..<endIndex, in: self),
            withTemplate: ""
        )
    }

    var removingDuplicateEmbeddedImages: String {
        let pattern = #"(?is)<img\b[^>]*\bsrc\s*=\s*["']([^"']+)["'][^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }

        let fullRange = NSRange(startIndex..<endIndex, in: self)
        let matches = regex.matches(in: self, range: fullRange)
        var seenSources = Set<String>()
        var duplicateRanges: [NSRange] = []

        for match in matches {
            guard match.numberOfRanges > 1,
                  let sourceRange = Range(match.range(at: 1), in: self) else {
                continue
            }
            let source = String(self[sourceRange])
                .removingPercentEncoding?
                .lowercased() ?? String(self[sourceRange]).lowercased()

            if seenSources.contains(source) {
                duplicateRanges.append(match.range)
            } else {
                seenSources.insert(source)
            }
        }

        let mutableHTML = NSMutableString(string: self)
        for range in duplicateRanges.reversed() {
            mutableHTML.replaceCharacters(in: range, with: "")
        }
        return mutableHTML as String
    }
}
