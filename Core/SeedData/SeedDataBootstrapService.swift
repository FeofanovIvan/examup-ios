import Foundation

protocol SeedDataBootstrapServicing {
    func bootstrapIfNeeded() async
    func bootstrapBundledFreeContent(subjectID: String) async
}

struct SeedDataBootstrapService: SeedDataBootstrapServicing {
    private let datasets: [SeedDataset]
    private let fileProvider: SeedDataFileProviding
    private let decoder: EducationalContentSeedDecoding
    private let contentStore: EducationalContentStore
    private let stateStore: SeedImportStateStoring

    init(
        datasets: [SeedDataset] = SeedDatasetCatalog.all,
        fileProvider: SeedDataFileProviding,
        decoder: EducationalContentSeedDecoding,
        contentStore: EducationalContentStore,
        stateStore: SeedImportStateStoring
    ) {
        self.datasets = datasets
        self.fileProvider = fileProvider
        self.decoder = decoder
        self.contentStore = contentStore
        self.stateStore = stateStore
    }

    func bootstrapIfNeeded() async {
        let start = Date()
        #if DEBUG
        print("[SeedData][Bootstrap] started datasets=\(datasets.count)")
        #endif
        for dataset in datasets {
            await importDatasetIfNeeded(dataset)
        }
        #if DEBUG
        let elapsed = Date().timeIntervalSince(start)
        print("[SeedData][Bootstrap] finished elapsed=\(String(format: "%.2f", elapsed))s")
        #endif
    }

    func bootstrapBundledFreeContent(subjectID: String) async {
        let freeDatasets = datasets.filter {
            $0.subject.id == subjectID
                && SubjectLibraryCatalog.library(subjectID: subjectID)?.hasBundledFreeVersion == true
        }
        for dataset in freeDatasets {
            do {
                let bundledURL = try fileProvider.prepareBundledSeedFile(for: dataset)
                let database = try decoder.decode(from: bundledURL, dataset: dataset)
                try await contentStore.replaceContent(database)
                #if DEBUG
                print("[SeedData][Teacher] bundled free imported dataset=\(dataset.id.rawValue) tasks=\(database.tasks.count)")
                #endif
            } catch {
                #if DEBUG
                print("[SeedData][Teacher] bundled free failed dataset=\(dataset.id.rawValue): \(error.seedDataDebugDescription)")
                #endif
            }
        }
    }

    private func importDatasetIfNeeded(_ dataset: SeedDataset) async {
        let start = Date()
        #if DEBUG
        print("[SeedData][Import] start dataset=\(dataset.id.rawValue) resource=\(dataset.resourceName).\(dataset.resourceExtension)")
        #endif
        do {
            let localURL = try fileProvider.prepareLocalSeedFile(for: dataset)
            #if DEBUG
            print("[SeedData][Import] file ready dataset=\(dataset.id.rawValue) path=\(localURL.path)")
            #endif
            let database = try decoder.decode(from: localURL, dataset: dataset)
            try await contentStore.replaceContent(database)
            stateStore.markImported(dataset, version: database.version)
            #if DEBUG
            let elapsed = Date().timeIntervalSince(start)
            print("[SeedData][Import] success dataset=\(dataset.id.rawValue) tasks=\(database.tasks.count) blocks=\(database.blocks.count) elapsed=\(String(format: "%.2f", elapsed))s")
            #endif
        } catch {
            #if DEBUG
            print("[SeedData][Import] failed dataset=\(dataset.id.rawValue): \(error.seedDataDebugDescription)")
            #endif
        }
    }
}

private extension Error {
    var seedDataDebugDescription: String {
        guard let decodingError = self as? DecodingError else {
            return localizedDescription
        }

        switch decodingError {
        case .typeMismatch(let type, let context):
            return "typeMismatch type=\(type) path=\(context.codingPath.seedDataPath) debug=\(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "valueNotFound type=\(type) path=\(context.codingPath.seedDataPath) debug=\(context.debugDescription)"
        case .keyNotFound(let key, let context):
            return "keyNotFound key=\(key.stringValue) path=\(context.codingPath.seedDataPath) debug=\(context.debugDescription)"
        case .dataCorrupted(let context):
            return "dataCorrupted path=\(context.codingPath.seedDataPath) debug=\(context.debugDescription)"
        @unknown default:
            return localizedDescription
        }
    }
}

private extension Array where Element == CodingKey {
    var seedDataPath: String {
        map(\.stringValue).joined(separator: ".")
    }
}
