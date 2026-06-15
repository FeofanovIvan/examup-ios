import Foundation

protocol EducationalContentStore {
    func replaceContent(_ database: EducationalContentDatabase) async throws
    func loadDatabase(datasetID: String) async throws -> EducationalContentDatabase?
    func loadSummaries() async throws -> [EducationalContentSummary]
}

actor InMemoryEducationalContentStore: EducationalContentStore {
    private var databases: [String: EducationalContentDatabase] = [:]

    func replaceContent(_ database: EducationalContentDatabase) async throws {
        guard let existing = databases[database.datasetID] else {
            databases[database.datasetID] = database
            return
        }

        let mergedTasksByID = (existing.tasks + database.tasks).reduce(into: [String: EducationalTask]()) {
            $0[$1.id] = $1
        }
        let mergedBlocksByID = (existing.blocks + database.blocks).reduce(into: [String: EducationalContentBlock]()) {
            guard let current = $0[$1.id] else {
                $0[$1.id] = $1
                return
            }
            $0[$1.id] = EducationalContentBlock(
                id: $1.id,
                title: $1.title,
                subjectID: $1.subjectID,
                examCategory: $1.examCategory,
                taskIDs: Array(Set(current.taskIDs + $1.taskIDs)).sorted()
            )
        }
        let mergedTasks = mergedTasksByID.values.sorted { $0.id < $1.id }
        let mergedBlocks = mergedBlocksByID.values.sorted { $0.id < $1.id }

        databases[database.datasetID] = EducationalContentDatabase(
            datasetID: database.datasetID,
            title: database.title,
            subject: database.subject,
            examCategory: database.examCategory,
            level: database.level,
            version: max(existing.version, database.version),
            source: database.source ?? existing.source,
            blocks: mergedBlocks,
            tasks: mergedTasks
        )
    }

    func loadDatabase(datasetID: String) async throws -> EducationalContentDatabase? {
        databases[datasetID]
    }

    func loadSummaries() async throws -> [EducationalContentSummary] {
        databases.values
            .map {
                EducationalContentSummary(
                    id: $0.datasetID,
                    title: $0.title,
                    subject: $0.subject,
                    examCategory: $0.examCategory,
                    level: $0.level,
                    version: $0.version,
                    taskCount: $0.tasks.count
                )
            }
            .sorted { $0.title < $1.title }
    }
}
