import Foundation

protocol SeedDataFileProviding {
    func prepareLocalSeedFile(for dataset: SeedDataset) throws -> URL
    func prepareBundledSeedFile(for dataset: SeedDataset) throws -> URL
}

struct SeedDataFileProvider: SeedDataFileProviding {
    private let fileManager: FileManager
    private let bundle: Bundle

    init(fileManager: FileManager = .default, bundle: Bundle = .main) {
        self.fileManager = fileManager
        self.bundle = bundle
    }

    func prepareLocalSeedFile(for dataset: SeedDataset) throws -> URL {
        if let downloadedURL = SubjectLibraryCatalog.downloadedDatabaseURL(
            for: dataset.subject.id,
            fileManager: fileManager
        ) {
            #if DEBUG
            print("[SeedData][FileProvider] using downloaded library: \(downloadedURL.lastPathComponent)")
            #endif
            return downloadedURL
        }

        let bundledURL = try prepareBundledSeedFile(for: dataset)
        #if DEBUG
        print("[SeedData][FileProvider] using bundled file without local duplicate: \(dataset.localFilename)")
        #endif
        return bundledURL
    }

    func prepareBundledSeedFile(for dataset: SeedDataset) throws -> URL {
        guard let url = bundle.url(
            forResource: dataset.resourceName,
            withExtension: dataset.resourceExtension,
            subdirectory: "SeedData"
        ) ?? bundle.url(
            forResource: dataset.resourceName,
            withExtension: dataset.resourceExtension
        ) else {
            throw SeedDataError.bundledFileNotFound(dataset.localFilename)
        }
        return url
    }
}

enum SeedDataError: LocalizedError {
    case applicationSupportDirectoryUnavailable
    case bundledFileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .applicationSupportDirectoryUnavailable:
            return "Application Support directory is unavailable."
        case .bundledFileNotFound(let filename):
            return "Bundled seed file was not found: \(filename)."
        }
    }
}
