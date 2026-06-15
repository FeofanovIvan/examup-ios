import Foundation

protocol StudentAssignmentAttachmentCaching {
    func cacheAttachment(
        _ attachment: TeacherAssignmentAttachment,
        assignmentID: String,
        itemID: String
    ) async throws -> URL
}

struct FileSystemStudentAssignmentAttachmentCache: StudentAssignmentAttachmentCaching {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func cacheAttachment(
        _ attachment: TeacherAssignmentAttachment,
        assignmentID: String,
        itemID: String
    ) async throws -> URL {
        let directory = try cacheDirectory(assignmentID: assignmentID, itemID: itemID)
        let targetURL = directory.appendingPathComponent(attachment.filename.sanitizedAssignmentFilename)

        if fileManager.fileExists(atPath: targetURL.path) {
            return targetURL
        }

        guard let remoteURL = URL(string: attachment.url) else {
            throw StudentAssignmentAttachmentCacheError.invalidURL
        }

        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw StudentAssignmentAttachmentCacheError.downloadFailed
        }

        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        try fileManager.moveItem(at: temporaryURL, to: targetURL)
        return targetURL
    }

    private func cacheDirectory(assignmentID: String, itemID: String) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("ExamUpAssignments", isDirectory: true)
        .appendingPathComponent(assignmentID.sanitizedAssignmentFilename, isDirectory: true)
        .appendingPathComponent(itemID.sanitizedAssignmentFilename, isDirectory: true)

        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}

enum StudentAssignmentAttachmentCacheError: LocalizedError {
    case invalidURL
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректная ссылка на файл задания"
        case .downloadFailed:
            return "Не удалось скачать файл задания"
        }
    }
}

private extension String {
    var sanitizedAssignmentFilename: String {
        let allowed = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: ".-_"))
        let scalars = unicodeScalars.map { scalar in
            allowed.contains(scalar) ? String(scalar) : "-"
        }
        let value = scalars.joined()
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-"))
        return value.isEmpty ? "file" : value
    }
}
