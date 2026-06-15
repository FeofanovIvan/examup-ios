import CryptoKit
import Foundation

protocol ExamSafeModeArchiveStoring {
    func createArchive(sessionID: ExamSession.ID) async throws -> ExamSafeModeArchive
    func saveCapture(_ jpegData: Data, capture: ExamSafeModeCapture, archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive
    func saveTranscriptSegment(_ segment: ExamSafeModeTranscriptSegment, archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive
    func finishArchive(_ archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive
    func saveReport(_ report: ExamSafeModeReport, pdfData: Data?, archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive
}

actor FileExamSafeModeArchiveStore: ExamSafeModeArchiveStoring {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createArchive(sessionID: ExamSession.ID) async throws -> ExamSafeModeArchive {
        let folderURL = try archiveFolderURL(sessionID: sessionID)
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let archive = ExamSafeModeArchive(
            id: sessionID,
            sessionID: sessionID,
            folderURL: folderURL,
            captures: [],
            transcriptSegments: [],
            startedAt: Date(),
            finishedAt: nil,
            fileHashes: [:]
        )
        try writeManifest(archive)
        return archive
    }

    func saveCapture(_ jpegData: Data, capture: ExamSafeModeCapture, archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive {
        let fileURL = archive.folderURL.appendingPathComponent(capture.filename, isDirectory: false)
        try jpegData.write(to: fileURL, options: [.atomic])

        var updatedArchive = archive
        updatedArchive.captures.append(capture)
        updatedArchive.fileHashes[capture.filename] = sha256(of: jpegData)
        try writeManifest(updatedArchive)
        return updatedArchive
    }

    func saveTranscriptSegment(_ segment: ExamSafeModeTranscriptSegment, archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive {
        var updatedArchive = archive
        updatedArchive.transcriptSegments.append(segment)
        try appendTranscriptSegment(segment, to: archive.folderURL)
        try writeTranscriptText(updatedArchive)
        try writeManifest(updatedArchive)
        return updatedArchive
    }

    func finishArchive(_ archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive {
        var updatedArchive = archive
        updatedArchive.finishedAt = Date()
        // Hash the transcript files now that they are final
        let transcriptURL = archive.folderURL.appendingPathComponent("transcript.txt")
        if let data = try? Data(contentsOf: transcriptURL) {
            updatedArchive.fileHashes["transcript.txt"] = sha256(of: data)
        }
        try writeManifest(updatedArchive)
        return updatedArchive
    }

    func saveReport(_ report: ExamSafeModeReport, pdfData: Data?, archive: ExamSafeModeArchive) async throws -> ExamSafeModeArchive {
        var updatedArchive = archive

        // Save report JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let reportData = try encoder.encode(report)
        let reportURL = archive.folderURL.appendingPathComponent("report.json", isDirectory: false)
        try reportData.write(to: reportURL, options: [.atomic])
        updatedArchive.fileHashes["report.json"] = sha256(of: reportData)

        // Save PDF if provided
        if let pdfData {
            let pdfURL = archive.folderURL.appendingPathComponent("report.pdf", isDirectory: false)
            try pdfData.write(to: pdfURL, options: [.atomic])
            updatedArchive.fileHashes["report.pdf"] = sha256(of: pdfData)
        }

        try writeManifest(updatedArchive)
        return updatedArchive
    }

    // MARK: - Helpers

    private func archiveFolderURL(sessionID: ExamSession.ID) throws -> URL {
        guard let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return supportURL
            .appendingPathComponent("ExamSafeModeArchives", isDirectory: true)
            .appendingPathComponent(sessionID, isDirectory: true)
    }

    private func writeManifest(_ archive: ExamSafeModeArchive) throws {
        let manifestURL = archive.folderURL.appendingPathComponent("manifest.json", isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(archive)
        try data.write(to: manifestURL, options: [.atomic])
    }

    private func appendTranscriptSegment(_ segment: ExamSafeModeTranscriptSegment, to folderURL: URL) throws {
        let fileURL = folderURL.appendingPathComponent("transcript.jsonl", isDirectory: false)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(segment)
        var line = data
        line.append(0x0A)

        if fileManager.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try line.write(to: fileURL, options: [.atomic])
        }
    }

    private func writeTranscriptText(_ archive: ExamSafeModeArchive) throws {
        let fileURL = archive.folderURL.appendingPathComponent("transcript.txt", isDirectory: false)
        let text = archive.transcriptSegments
            .filter(\.isFinal)
            .map(\.text)
            .joined(separator: "\n")
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func sha256(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
