import Foundation

/// Resolves the SafeMode archive for a given session and produces share-ready URLs:
/// - `report.pdf` (if the session had SafeMode and the PDF was generated)
/// - a `.zip` of the entire archive folder (captures, transcript, manifest, report)
enum ExamArchiveShareService {
    static func loadReport(for sessionID: String) -> ExamSafeModeReport? {
        let reportURL = archiveFolderURL(for: sessionID).appendingPathComponent("report.json")
        guard let data = try? Data(contentsOf: reportURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExamSafeModeReport.self, from: data)
    }

    static func deleteArchive(for sessionID: String) throws {
        let folderURL = archiveFolderURL(for: sessionID)
        guard FileManager.default.fileExists(atPath: folderURL.path) else { return }
        try FileManager.default.removeItem(at: folderURL)
    }

    /// Returns an ordered list of file URLs ready for `UIActivityViewController`.
    /// PDF comes first (opens inline in most apps), ZIP second.
    /// Returns an empty array when no archive exists for this session.
    static func shareURLs(for sessionID: String) async -> [URL] {
        let archiveFolder = archiveFolderURL(for: sessionID)
        let fm = FileManager.default

        guard fm.fileExists(atPath: archiveFolder.path) else { return [] }

        var urls: [URL] = []

        // ── 1. PDF report ──────────────────────────────────────────────────────
        let pdfURL = archiveFolder.appendingPathComponent("report.pdf")
        if fm.fileExists(atPath: pdfURL.path) {
            urls.append(pdfURL)
        }

        // ── 2. ZIP archive ──────────────────────────────────────────────────────
        let zipURL = zipDestinationURL(for: sessionID)
        do {
            // Always recreate to pick up the latest files
            if fm.fileExists(atPath: zipURL.path) {
                try fm.removeItem(at: zipURL)
            }
            try ZipArchiveCreator.createZip(from: archiveFolder, to: zipURL)
            urls.append(zipURL)
        } catch {
            #if DEBUG
            print("[ShareService] failed to create zip for session=\(sessionID): \(error.localizedDescription)")
            #endif
        }

        return urls
    }

    // MARK: - Paths

    static func archiveFolderURL(for sessionID: String) -> URL {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return support
            .appendingPathComponent("ExamSafeModeArchives", isDirectory: true)
            .appendingPathComponent(sessionID, isDirectory: true)
    }

    private static func zipDestinationURL(for sessionID: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("examup_archive_\(sessionID).zip")
    }
}
