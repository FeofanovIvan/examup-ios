import Foundation

protocol SeedImportStateStoring {
    func importedVersion(for dataset: SeedDataset) -> Int?
    func markImported(_ dataset: SeedDataset, version: Int)
}

struct SeedImportStateStore: SeedImportStateStoring {
    private let keyValueStorage: KeyValueStorage

    init(keyValueStorage: KeyValueStorage) {
        self.keyValueStorage = keyValueStorage
    }

    func importedVersion(for dataset: SeedDataset) -> Int? {
        guard keyValueStorage.string(for: dataset.importedKey) == "true" else { return nil }
        return keyValueStorage.string(for: dataset.versionKey).flatMap(Int.init)
    }

    func markImported(_ dataset: SeedDataset, version: Int) {
        keyValueStorage.set("true", for: dataset.importedKey)
        keyValueStorage.set(String(version), for: dataset.versionKey)
    }
}
