import Foundation
import CryptoKit
import ZIPFoundation

struct SubjectLibrary: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String
    let tintHex: String
    let manifestFileID: String
    let databaseFileID: String
    let databaseFilename: String
    let bundledFreeFilename: String?
    let mediaArchiveFileID: String?
    let mediaArchiveFilename: String?

    var hasBundledFreeVersion: Bool {
        bundledFreeFilename != nil
    }

    var hasRemoteMediaArchive: Bool {
        mediaArchiveFileID != nil && mediaArchiveFilename != nil
    }
}

enum SubjectLibraryCatalog {
    static let releaseCatalogFileID = "1lpBZEU-5c2mMd4b5rFGeQkQ7hakedsgO"

    static let all: [SubjectLibrary] = [
        SubjectLibrary(
            id: "english",
            title: "Английский язык",
            systemImage: "character.book.closed",
            tintHex: "4D8DF7",
            manifestFileID: "1SpILktzkOpXDSdKkzyK4ygUB5cCKl-6P",
            databaseFileID: "1akU1Y5IV7u42jxwYRnvismWDmrWOjUlZ",
            databaseFilename: "ExamUP_English.json",
            bundledFreeFilename: nil,
            mediaArchiveFileID: "17cb2PT0RQabmQVEQCdXnVAwGUss3hO4D",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "biology",
            title: "Биология",
            systemImage: "leaf",
            tintHex: "35A96B",
            manifestFileID: "1X7eO1Ql0-qOSXyJHBMBZynSFfWMeOAKY",
            databaseFileID: "12CWypdV5LHZHY0Zq33jKGKEI_neqd5IN",
            databaseFilename: "ExamUP_Biology.json",
            bundledFreeFilename: nil,
            mediaArchiveFileID: "1EQBKy9jltyjtge6vcns3_twFjCVYAWDo",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "computer-science",
            title: "Информатика",
            systemImage: "desktopcomputer",
            tintHex: "5E63D8",
            manifestFileID: "1EsfHvq1ss9LMaYiFGeqZKUQLvCu_-Z3H",
            databaseFileID: "1IPcjfegBGe5AbmkhygFITT4Jy83kM9xb",
            databaseFilename: "ExamUP_Computer_Science.json",
            bundledFreeFilename: nil,
            mediaArchiveFileID: "1xS1vg9Mk2WPdohgA-xSPP-AdSQwFuSj8",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "history",
            title: "История",
            systemImage: "building.columns",
            tintHex: "B57942",
            manifestFileID: "1qYk3kDO4td-HSdkXpQrvcceKtA1rbg1S",
            databaseFileID: "1nzFIm-WsvUei4OREIOgeAHdJWyAavoEs",
            databaseFilename: "ExamUP_History.json",
            bundledFreeFilename: nil,
            mediaArchiveFileID: "1yfGvHYvz9AB-NbPoQg9owD3Is59ud1tR",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "math",
            title: "Математика",
            systemImage: "function",
            tintHex: "7257F4",
            manifestFileID: "1blTG6e7PaLazDEPEQQjqq77DlL_l41iZ",
            databaseFileID: "1qjLq93Ls0hn9A5y3tdvaREl47sOLjwTz",
            databaseFilename: "ExamUP_Math.json",
            bundledFreeFilename: "ExamUP_Math_Free.json",
            mediaArchiveFileID: "1DLrfHIQrx9uWD9C88WDvE6h8zS8UMhBu",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "russian",
            title: "Русский язык",
            systemImage: "text.book.closed",
            tintHex: "D45D79",
            manifestFileID: "1L3Eg0hnLMBcCbKz3MImO19b73GvPaPcB",
            databaseFileID: "1qq7xnpQEBszhoyE_N2oQGYwZeAkGU0Mi",
            databaseFilename: "ExamUP_Russion.json",
            bundledFreeFilename: "ExamUP_Russion_Free.json",
            mediaArchiveFileID: "1m6PwrFEbKjndv_ATvZvzWzzPJMJ8T5qw",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "physics",
            title: "Физика",
            systemImage: "atom",
            tintHex: "2D9BA8",
            manifestFileID: "1mQuIRdQDwGxaBBjXEqoi44JQK-BogBHq",
            databaseFileID: "1__kHH0PM1PelF5mWMNaM13sQmuoH9Ypk",
            databaseFilename: "ExamUP_Physics.json",
            bundledFreeFilename: nil,
            mediaArchiveFileID: "1SPyuiRRHptlvu7wQ2wEgGRGGRp8Kxfh2",
            mediaArchiveFilename: "resources.zip"
        ),
        SubjectLibrary(
            id: "chemistry",
            title: "Химия",
            systemImage: "flask",
            tintHex: "E08A32",
            manifestFileID: "1DGxPG622HqZn51kRMlVTDeuOihvuVUEw",
            databaseFileID: "1-w0admQ2ThfdEqXf3zEo0paEPBwDDgPj",
            databaseFilename: "ExamUP_Chemistry.json",
            bundledFreeFilename: nil,
            mediaArchiveFileID: "1dvGoC30uPTmVIhQj3Dkwx6uxzK4YxgTt",
            mediaArchiveFilename: "resources.zip"
        )
    ]

    static func library(subjectID: String) -> SubjectLibrary? {
        all.first { $0.id == subjectID }
    }

    static func downloadedDatabaseURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        guard let library = library(subjectID: subjectID),
              let root = try? librariesRootURL(fileManager: fileManager) else {
            return nil
        }
        let url = root
            .appendingPathComponent(library.id, isDirectory: true)
            .appendingPathComponent(library.databaseFilename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func downloadedMediaRootURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        guard let subjectRoot = downloadedLibraryRootURL(for: subjectID, fileManager: fileManager) else {
            return nil
        }
        let url = subjectRoot.appendingPathComponent("resources", isDirectory: true)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func downloadedLibraryRootURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        guard let root = try? librariesRootURL(fileManager: fileManager) else {
            return nil
        }
        let url = root.appendingPathComponent(subjectID, isDirectory: true)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    static func installedManifestURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        downloadedLibraryRootURL(for: subjectID, fileManager: fileManager)?
            .appendingPathComponent("installed-manifest.json", isDirectory: false)
    }

    static func resourceBaseURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        downloadedMediaRootURL(for: subjectID, fileManager: fileManager) == nil
            ? nil
            : downloadedLibraryRootURL(for: subjectID, fileManager: fileManager)
    }

    static func partialDatabaseURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        guard let library = library(subjectID: subjectID),
              let root = try? librariesRootURL(fileManager: fileManager) else {
            return nil
        }
        return root
            .appendingPathComponent(library.id, isDirectory: true)
            .appendingPathComponent("\(library.databaseFilename).partial")
    }

    static func partialArchiveURL(for subjectID: String, fileManager: FileManager = .default) -> URL? {
        guard let library = library(subjectID: subjectID),
              let archiveFilename = library.mediaArchiveFilename,
              let root = try? librariesRootURL(fileManager: fileManager) else {
            return nil
        }
        return root
            .appendingPathComponent(library.id, isDirectory: true)
            .appendingPathComponent("\(archiveFilename).partial")
    }

    static func librariesRootURL(fileManager: FileManager = .default) throws -> URL {
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw SeedDataError.applicationSupportDirectoryUnavailable
        }
        return applicationSupport.appendingPathComponent("SubjectLibraries", isDirectory: true)
    }
}

struct SubjectLibraryStatus: Identifiable, Equatable {
    let library: SubjectLibrary
    let isDownloaded: Bool
    let partialBytes: Int64

    var id: String { library.id }

    var isAvailable: Bool {
        library.hasBundledFreeVersion || isDownloaded
    }
}

private struct SubjectReleaseManifest: Codable {
    let version: String
    let databases: [Database]
    let resources: Resources

    struct Database: Codable {
        let file: String
        let size: Int64
        let sha256: String
    }

    struct Resources: Codable {
        let file: String
        let size: Int64
        let sha256: String
        let rootFolder: String

        enum CodingKeys: String, CodingKey {
            case file
            case size
            case sha256
            case rootFolder = "root_folder"
        }
    }
}

protocol SubjectLibraryManaging {
    func loadStatuses() async -> [SubjectLibraryStatus]
    func downloadSize(for library: SubjectLibrary) async -> Int64?
    func importInstalled(_ library: SubjectLibrary) async throws -> Bool
    func updateIfNeeded(_ library: SubjectLibrary) async throws
    func download(_ library: SubjectLibrary) async throws
}

actor DefaultSubjectLibraryManager: SubjectLibraryManaging {
    private let fileManager: FileManager
    private let decoder: EducationalContentSeedDecoding
    private let contentStore: EducationalContentStore
    private var manifestCache: [String: SubjectReleaseManifest] = [:]

    init(
        fileManager: FileManager = .default,
        decoder: EducationalContentSeedDecoding,
        contentStore: EducationalContentStore
    ) {
        self.fileManager = fileManager
        self.decoder = decoder
        self.contentStore = contentStore
    }

    func loadStatuses() async -> [SubjectLibraryStatus] {
        SubjectLibraryCatalog.all.map {
            SubjectLibraryStatus(
                library: $0,
                isDownloaded: SubjectLibraryCatalog.downloadedDatabaseURL(
                    for: $0.id,
                    fileManager: fileManager
                ) != nil && SubjectLibraryCatalog.downloadedMediaRootURL(
                    for: $0.id,
                    fileManager: fileManager
                ) != nil,
                partialBytes: partialBytes(for: $0)
            )
        }
    }

    func download(_ library: SubjectLibrary) async throws {
        #if DEBUG
        print("[SubjectLib][Download] download() called subject=\(library.id)")
        #endif
        let releaseManifest: SubjectReleaseManifest
        do {
            releaseManifest = try await manifest(for: library)
        } catch {
            if try await importInstalled(library) {
                return
            }
            throw error
        }
        if try await useInstalledLibraryIfCurrent(
            library,
            releaseManifest: releaseManifest,
            importWhenCurrent: true
        ) {
            return
        }
        try await install(library, releaseManifest: releaseManifest)
    }

    func importInstalled(_ library: SubjectLibrary) async throws -> Bool {
        guard let existingURL = installedDatabaseURL(for: library) else {
            return false
        }
        try await importDatabase(at: existingURL, for: library)
        return true
    }

    func updateIfNeeded(_ library: SubjectLibrary) async throws {
        let releaseManifest = try await manifest(for: library, ignoreCache: true)
        if try await useInstalledLibraryIfCurrent(
            library,
            releaseManifest: releaseManifest,
            importWhenCurrent: false
        ) {
            return
        }
        try await install(library, releaseManifest: releaseManifest)
    }

    private func install(_ library: SubjectLibrary, releaseManifest: SubjectReleaseManifest) async throws {
        guard let archiveFileID = library.mediaArchiveFileID,
              let archiveFilename = library.mediaArchiveFilename else {
            throw SubjectLibraryError.missingResourcesArchive
        }
        guard let database = releaseManifest.databases.first(where: {
            $0.file == library.databaseFilename
        }) else {
            throw SubjectLibraryError.invalidManifest
        }

        let destinationDirectory = try SubjectLibraryCatalog.librariesRootURL(fileManager: fileManager)
            .appendingPathComponent(library.id, isDirectory: true)
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let destinationURL = destinationDirectory.appendingPathComponent(library.databaseFilename)
        let partialURL = destinationDirectory.appendingPathComponent("\(library.databaseFilename).partial")
        let archivePartialURL = destinationDirectory.appendingPathComponent("\(archiveFilename).partial")

        try await downloadFile(
            fileID: library.databaseFileID,
            partialURL: partialURL,
            expectedSize: database.size,
            expectedSHA256: database.sha256
        )

        guard try isLikelyJSON(at: partialURL) else {
            try? fileManager.removeItem(at: partialURL)
            throw SubjectLibraryError.invalidDatabase
        }

        try await downloadFile(
            fileID: archiveFileID,
            partialURL: archivePartialURL,
            expectedSize: releaseManifest.resources.size,
            expectedSHA256: releaseManifest.resources.sha256
        )

        let stagingURL = destinationDirectory.appendingPathComponent("resources.staging", isDirectory: true)
        try? fileManager.removeItem(at: stagingURL)
        try fileManager.createDirectory(at: stagingURL, withIntermediateDirectories: true)
        do {
            try fileManager.unzipItem(at: archivePartialURL, to: stagingURL)
        } catch {
            try? fileManager.removeItem(at: stagingURL)
            throw SubjectLibraryError.archiveExtractionFailed
        }

        let extractedResourcesURL = stagingURL
            .appendingPathComponent(releaseManifest.resources.rootFolder, isDirectory: true)
        guard fileManager.fileExists(atPath: extractedResourcesURL.path) else {
            #if DEBUG
            print("[SubjectLib][Download] extracted folder not found rootFolder=\(releaseManifest.resources.rootFolder) — removing staging")
            #endif
            try? fileManager.removeItem(at: stagingURL)
            throw SubjectLibraryError.archiveExtractionFailed
        }
        #if DEBUG
        if !fileManager.fileExists(atPath: extractedResourcesURL.appendingPathComponent("examup-responsive.css").path) {
            print("[SubjectLib][Download] examup-responsive.css not found — library will work without styles")
        }
        #endif

        let resourcesURL = destinationDirectory.appendingPathComponent("resources", isDirectory: true)
        try? fileManager.removeItem(at: resourcesURL)
        try fileManager.moveItem(at: extractedResourcesURL, to: resourcesURL)
        try? fileManager.removeItem(at: stagingURL)
        try? fileManager.removeItem(at: archivePartialURL)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: partialURL, to: destinationURL)

        do {
            try await importDatabase(at: destinationURL, for: library)
        } catch {
            try? fileManager.removeItem(at: destinationURL)
            throw error
        }
        try writeInstalledManifest(releaseManifest, for: library)

        #if DEBUG
        print("[SubjectLib][Download] ✅ installed subject=\(library.id) version=\(releaseManifest.version)")
        #endif
        NotificationCenter.default.post(name: .subjectLibraryDidInstall, object: library.id)
    }

    func downloadSize(for library: SubjectLibrary) async -> Int64? {
        if let manifest = try? await manifest(for: library),
           let database = manifest.databases.first(where: { $0.file == library.databaseFilename }) {
            return database.size + manifest.resources.size
        }
        guard let remoteURL = try? remoteURL(for: library.databaseFileID) else {
            return nil
        }
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "HEAD"
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              response.expectedContentLength > 0 else {
            return nil
        }
        return response.expectedContentLength
    }

    private func importDatabase(at url: URL, for library: SubjectLibrary) async throws {
        let datasets = SeedDatasetCatalog.all.filter { $0.subject.id == library.id }
        for dataset in datasets {
            let database = try decoder.decode(from: url, dataset: dataset)
            try await contentStore.replaceContent(database)
        }
    }

    private func remoteURL(for fileID: String) throws -> URL {
        guard let url = URL(
            string: "https://drive.usercontent.google.com/download?id=\(fileID)&export=download&confirm=t"
        ) else {
            throw SubjectLibraryError.invalidDownloadURL
        }
        return url
    }

    private func manifest(for library: SubjectLibrary, ignoreCache: Bool = false) async throws -> SubjectReleaseManifest {
        if !ignoreCache, let cached = manifestCache[library.id] {
            #if DEBUG
            print("[SubjectLib][Manifest] using cache subject=\(library.id)")
            #endif
            return cached
        }
        let url = try remoteURL(for: library.manifestFileID)
        #if DEBUG
        print("[SubjectLib][Manifest] fetching subject=\(library.id) url=\(url)")
        #endif
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            #if DEBUG
            print("[SubjectLib][Manifest] HTTP error subject=\(library.id) status=\((response as? HTTPURLResponse)?.statusCode ?? -1)")
            #endif
            throw SubjectLibraryError.downloadFailed
        }
        #if DEBUG
        print("[SubjectLib][Manifest] received subject=\(library.id) bytes=\(data.count) preview=\(String(data: data.prefix(200), encoding: .utf8) ?? "<non-utf8>")")
        #endif
        do {
            let manifest = try JSONDecoder().decode(SubjectReleaseManifest.self, from: data)
            manifestCache[library.id] = manifest
            #if DEBUG
            print("[SubjectLib][Manifest] decoded subject=\(library.id) version=\(manifest.version) dbCount=\(manifest.databases.count) resourcesSize=\(manifest.resources.size)")
            #endif
            return manifest
        } catch {
            #if DEBUG
            print("[SubjectLib][Manifest] decode error subject=\(library.id) error=\(error)")
            #endif
            throw error
        }
    }

    private func installedDatabaseURL(for library: SubjectLibrary) -> URL? {
        guard let databaseURL = SubjectLibraryCatalog.downloadedDatabaseURL(
            for: library.id,
            fileManager: fileManager
        ), SubjectLibraryCatalog.downloadedMediaRootURL(
            for: library.id,
            fileManager: fileManager
        ) != nil else {
            return nil
        }
        return databaseURL
    }

    private func useInstalledLibraryIfCurrent(
        _ library: SubjectLibrary,
        releaseManifest: SubjectReleaseManifest,
        importWhenCurrent: Bool
    ) async throws -> Bool {
        guard let databaseURL = installedDatabaseURL(for: library) else {
            return false
        }

        if let installedManifest = readInstalledManifest(for: library),
           installedManifest.version == releaseManifest.version {
            if importWhenCurrent {
                try await importDatabase(at: databaseURL, for: library)
            }
            return true
        }

        guard let database = releaseManifest.databases.first(where: {
            $0.file == library.databaseFilename
        }), fileSize(at: databaseURL) == database.size,
              try sha256(at: databaseURL) == database.sha256.lowercased() else {
            return false
        }

        // Libraries installed before version tracking are adopted without downloading
        // the large resources archive again when their database checksum is current.
        try writeInstalledManifest(releaseManifest, for: library)
        if importWhenCurrent {
            try await importDatabase(at: databaseURL, for: library)
        }
        return true
    }

    private func readInstalledManifest(for library: SubjectLibrary) -> SubjectReleaseManifest? {
        guard let url = SubjectLibraryCatalog.installedManifestURL(
            for: library.id,
            fileManager: fileManager
        ), let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(SubjectReleaseManifest.self, from: data)
    }

    private func writeInstalledManifest(
        _ manifest: SubjectReleaseManifest,
        for library: SubjectLibrary
    ) throws {
        guard let url = SubjectLibraryCatalog.installedManifestURL(
            for: library.id,
            fileManager: fileManager
        ) else {
            throw SubjectLibraryError.invalidManifest
        }
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: url, options: .atomic)
    }

    private func sha256(at url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func downloadFile(
        fileID: String,
        partialURL: URL,
        expectedSize: Int64,
        expectedSHA256: String
    ) async throws {
        if fileManager.fileExists(atPath: partialURL.path),
           fileSize(at: partialURL) == expectedSize,
           try sha256(at: partialURL) == expectedSHA256.lowercased() {
            #if DEBUG
            print("[SubjectLib][Download] already complete fileID=\(fileID) size=\(expectedSize)")
            #endif
            return
        }

        let remoteURL = try remoteURL(for: fileID)
        var request = URLRequest(url: remoteURL)
        let existingBytes = fileSize(at: partialURL)
        if existingBytes > 0, existingBytes < expectedSize {
            request.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
            #if DEBUG
            print("[SubjectLib][Download] resuming fileID=\(fileID) from=\(existingBytes) expected=\(expectedSize)")
            #endif
        } else {
            #if DEBUG
            print("[SubjectLib][Download] starting fileID=\(fileID) expected=\(expectedSize) url=\(remoteURL)")
            #endif
        }

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            #if DEBUG
            print("[SubjectLib][Download] HTTP error fileID=\(fileID) status=\((response as? HTTPURLResponse)?.statusCode ?? -1)")
            #endif
            throw SubjectLibraryError.downloadFailed
        }
        #if DEBUG
        print("[SubjectLib][Download] response fileID=\(fileID) status=\(httpResponse.statusCode) contentLength=\(httpResponse.expectedContentLength)")
        #endif

        let isResuming = httpResponse.statusCode == 206 && existingBytes > 0
        if !isResuming {
            try? fileManager.removeItem(at: partialURL)
            fileManager.createFile(atPath: partialURL.path, contents: nil)
        }
        try await write(bytes: bytes, to: partialURL)

        let downloadedSize = fileSize(at: partialURL)
        #if DEBUG
        print("[SubjectLib][Download] written fileID=\(fileID) size=\(downloadedSize) expected=\(expectedSize)")
        #endif

        guard downloadedSize == expectedSize,
              try sha256(at: partialURL) == expectedSHA256.lowercased() else {
            if downloadedSize >= expectedSize {
                #if DEBUG
                print("[SubjectLib][Download] checksum mismatch fileID=\(fileID) — removing partial")
                #endif
                try? fileManager.removeItem(at: partialURL)
                throw SubjectLibraryError.checksumMismatch
            }
            #if DEBUG
            print("[SubjectLib][Download] incomplete fileID=\(fileID) downloaded=\(downloadedSize) expected=\(expectedSize)")
            #endif
            throw SubjectLibraryError.incompleteDownload
        }
        #if DEBUG
        print("[SubjectLib][Download] verified fileID=\(fileID) ✓")
        #endif
    }

    private func fileSize(at url: URL) -> Int64 {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber else {
            return 0
        }
        return size.int64Value
    }

    private func partialBytes(for library: SubjectLibrary) -> Int64 {
        guard let url = SubjectLibraryCatalog.partialDatabaseURL(
            for: library.id,
            fileManager: fileManager
        ) else {
            return 0
        }
        let databaseBytes = fileSize(at: url)
        let archiveBytes = SubjectLibraryCatalog.partialArchiveURL(
            for: library.id,
            fileManager: fileManager
        ).map(fileSize(at:)) ?? 0
        return databaseBytes + archiveBytes
    }

    private func write(bytes: URLSession.AsyncBytes, to destinationURL: URL) async throws {
        let destination = try FileHandle(forWritingTo: destinationURL)
        defer { try? destination.close() }
        try destination.seekToEnd()

        var buffer = Data()
        buffer.reserveCapacity(262_144)
        do {
            for try await byte in bytes {
                buffer.append(byte)
                if buffer.count >= 262_144 {
                    try destination.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
            }
        } catch {
            if !buffer.isEmpty {
                try? destination.write(contentsOf: buffer)
            }
            throw error
        }

        if !buffer.isEmpty {
            try destination.write(contentsOf: buffer)
        }
    }

    private func expectedFinalSize(from response: HTTPURLResponse, existingBytes: Int64) -> Int64? {
        if let contentRange = response.value(forHTTPHeaderField: "Content-Range"),
           let totalText = contentRange.split(separator: "/").last,
           let total = Int64(totalText) {
            return total
        }
        guard response.expectedContentLength > 0 else { return nil }
        return existingBytes + response.expectedContentLength
    }

    private func isLikelyJSON(at url: URL) throws -> Bool {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let prefix = try handle.read(upToCount: 512) ?? Data()
        guard let text = String(data: prefix, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              let first = text.first else {
            return false
        }
        return first == "{" || first == "["
    }
}

extension Notification.Name {
    static let subjectLibraryDidInstall = Notification.Name("subjectLibraryDidInstall")
}

enum SubjectLibraryError: LocalizedError {
    case invalidDownloadURL
    case downloadFailed
    case invalidDatabase
    case incompleteDownload
    case checksumMismatch
    case missingResourcesArchive
    case invalidManifest
    case archiveExtractionFailed

    var errorDescription: String? {
        switch self {
        case .invalidDownloadURL:
            return "Не удалось сформировать ссылку загрузки."
        case .downloadFailed:
            return "Google Drive не вернул файл базы данных."
        case .invalidDatabase:
            return "Загруженный файл не похож на базу данных. Повреждённая часть удалена."
        case .incompleteDownload:
            return "Сеть прервала загрузку. Полученная часть сохранена, следующая попытка продолжит скачивание."
        case .checksumMismatch:
            return "Проверка файла не пройдена. Повреждённая загрузка удалена."
        case .missingResourcesArchive:
            return "Для предмета не указан обязательный архив ресурсов."
        case .invalidManifest:
            return "Манифест предмета не содержит описание базы данных."
        case .archiveExtractionFailed:
            return "Не удалось распаковать ресурсы предмета. Библиотека не установлена."
        }
    }
}
