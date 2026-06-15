import Foundation

protocol LocalStorage {
    func save<T: Codable>(_ value: T, for key: String) async throws
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T?
    func removeValue(for key: String) async throws
}

protocol KeyValueStorage {
    func string(for key: String) -> String?
    func set(_ value: String?, for key: String)
}

protocol ExamSessionStore {
    func loadActiveSession() async throws -> ExamSession?
    func loadActiveSession(datasetID: String) async throws -> ExamSession?
    func loadAllSessions() async throws -> [ExamSession]
    func save(_ session: ExamSession) async throws
    func loadSession(id: ExamSession.ID) async throws -> ExamSession?
    func deleteSession(id: ExamSession.ID) async throws
}

protocol LocalDatabase: Sendable {
    func saveRecord<T: Codable & Sendable>(_ value: T, entity: String, id: String, syncStatus: SyncStatus) async throws
    func loadRecord<T: Codable & Sendable>(_ type: T.Type, entity: String, id: String) async throws -> T?
    func loadRecords<T: Codable & Sendable>(_ type: T.Type, entity: String) async throws -> [T]
    func deleteRecord(entity: String, id: String, syncStatus: SyncStatus) async throws
    func enqueue(_ mutation: SyncMutation) async throws
    func pendingMutations(limit: Int) async throws -> [SyncMutation]
    func markMutationSynced(id: String) async throws
    func markMutationFailed(id: String, message: String) async throws
}
