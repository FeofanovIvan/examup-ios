import Foundation
import SQLite3

actor SQLiteLocalDatabase: LocalDatabase {
    private let database: OpaquePointer
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(filename: String = "examup-core.sqlite") {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        decoder.dateDecodingStrategy = .millisecondsSince1970

        let fileManager = FileManager.default
        let supportURL = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = supportURL.appendingPathComponent("ExamUpCore", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(filename)

        var handle: OpaquePointer?
        guard sqlite3_open_v2(
            url.path,
            &handle,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let handle else {
            fatalError("Unable to open ExamUp local database")
        }
        database = handle

        try! Self.configure(handle)
    }

    deinit {
        sqlite3_close(database)
    }

    func saveRecord<T: Codable & Sendable>(
        _ value: T,
        entity: String,
        id: String,
        syncStatus: SyncStatus
    ) throws {
        let payload = try encoder.encode(value)
        let sql = """
        INSERT INTO records(entity, id, payload, sync_status, updated_at, deleted_at, local_revision)
        VALUES(?, ?, ?, ?, ?, NULL, 1)
        ON CONFLICT(entity, id) DO UPDATE SET
            payload = excluded.payload,
            sync_status = excluded.sync_status,
            updated_at = excluded.updated_at,
            deleted_at = NULL,
            local_revision = records.local_revision + 1
        """
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        bind(entity, at: 1, in: statement)
        bind(id, at: 2, in: statement)
        bind(payload, at: 3, in: statement)
        bind(syncStatus.rawValue, at: 4, in: statement)
        bind(Date().timeIntervalSince1970, at: 5, in: statement)
        try step(statement)
    }

    func loadRecord<T: Codable & Sendable>(_ type: T.Type, entity: String, id: String) throws -> T? {
        let statement = try prepare("SELECT payload FROM records WHERE entity = ? AND id = ? AND deleted_at IS NULL LIMIT 1")
        defer { sqlite3_finalize(statement) }
        bind(entity, at: 1, in: statement)
        bind(id, at: 2, in: statement)
        guard sqlite3_step(statement) == SQLITE_ROW, let data = data(at: 0, in: statement) else { return nil }
        return try decoder.decode(type, from: data)
    }

    func loadRecords<T: Codable & Sendable>(_ type: T.Type, entity: String) throws -> [T] {
        let statement = try prepare("SELECT payload FROM records WHERE entity = ? AND deleted_at IS NULL ORDER BY updated_at DESC")
        defer { sqlite3_finalize(statement) }
        bind(entity, at: 1, in: statement)

        var values: [T] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let data = data(at: 0, in: statement) {
                values.append(try decoder.decode(type, from: data))
            }
        }
        return values
    }

    func deleteRecord(entity: String, id: String, syncStatus: SyncStatus) throws {
        let statement = try prepare(
            "UPDATE records SET deleted_at = ?, updated_at = ?, sync_status = ?, local_revision = local_revision + 1 WHERE entity = ? AND id = ?"
        )
        defer { sqlite3_finalize(statement) }
        let now = Date().timeIntervalSince1970
        bind(now, at: 1, in: statement)
        bind(now, at: 2, in: statement)
        bind(syncStatus.rawValue, at: 3, in: statement)
        bind(entity, at: 4, in: statement)
        bind(id, at: 5, in: statement)
        try step(statement)
    }

    func enqueue(_ mutation: SyncMutation) throws {
        let payload = try encoder.encode(mutation)
        let statement = try prepare(
            "INSERT OR REPLACE INTO sync_outbox(id, payload, created_at, attempt_count, last_error) VALUES(?, ?, ?, ?, ?)"
        )
        defer { sqlite3_finalize(statement) }
        bind(mutation.id, at: 1, in: statement)
        bind(payload, at: 2, in: statement)
        bind(mutation.createdAt.timeIntervalSince1970, at: 3, in: statement)
        bind(mutation.attemptCount, at: 4, in: statement)
        bind(mutation.lastError, at: 5, in: statement)
        try step(statement)
    }

    func pendingMutations(limit: Int) throws -> [SyncMutation] {
        let statement = try prepare("SELECT payload FROM sync_outbox ORDER BY created_at ASC LIMIT ?")
        defer { sqlite3_finalize(statement) }
        bind(limit, at: 1, in: statement)

        var mutations: [SyncMutation] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let data = data(at: 0, in: statement) {
                mutations.append(try decoder.decode(SyncMutation.self, from: data))
            }
        }
        return mutations
    }

    func markMutationSynced(id: String) throws {
        let statement = try prepare("DELETE FROM sync_outbox WHERE id = ?")
        defer { sqlite3_finalize(statement) }
        bind(id, at: 1, in: statement)
        try step(statement)
    }

    func markMutationFailed(id: String, message: String) throws {
        guard var mutation = try pendingMutation(id: id) else { return }
        mutation.attemptCount += 1
        mutation.lastError = message
        try enqueue(mutation)
    }

    private func pendingMutation(id: String) throws -> SyncMutation? {
        let statement = try prepare("SELECT payload FROM sync_outbox WHERE id = ? LIMIT 1")
        defer { sqlite3_finalize(statement) }
        bind(id, at: 1, in: statement)
        guard sqlite3_step(statement) == SQLITE_ROW, let data = data(at: 0, in: statement) else { return nil }
        return try decoder.decode(SyncMutation.self, from: data)
    }

    private static func configure(_ database: OpaquePointer) throws {
        try execute("PRAGMA journal_mode = WAL", database: database)
        try execute("PRAGMA foreign_keys = ON", database: database)
        try execute("""
        CREATE TABLE IF NOT EXISTS records(
            entity TEXT NOT NULL,
            id TEXT NOT NULL,
            payload BLOB NOT NULL,
            sync_status TEXT NOT NULL,
            updated_at REAL NOT NULL,
            deleted_at REAL,
            local_revision INTEGER NOT NULL DEFAULT 1,
            remote_revision INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(entity, id)
        )
        """, database: database)
        try execute("""
        CREATE TABLE IF NOT EXISTS sync_outbox(
            id TEXT PRIMARY KEY NOT NULL,
            payload BLOB NOT NULL,
            created_at REAL NOT NULL,
            attempt_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
        )
        """, database: database)
        try execute("CREATE INDEX IF NOT EXISTS records_entity_updated_idx ON records(entity, updated_at DESC)", database: database)
        try execute("CREATE INDEX IF NOT EXISTS sync_outbox_created_idx ON sync_outbox(created_at ASC)", database: database)
        try execute("PRAGMA user_version = 1", database: database)
    }

    private static func execute(_ sql: String, database: OpaquePointer) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw SQLiteLocalDatabaseError.sqlite(message: String(cString: sqlite3_errmsg(database)))
        }
    }

    private func execute(_ sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw SQLiteLocalDatabaseError.sqlite(message: errorMessage)
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw SQLiteLocalDatabaseError.sqlite(message: errorMessage)
        }
        return statement
    }

    private func step(_ statement: OpaquePointer) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteLocalDatabaseError.sqlite(message: errorMessage)
        }
    }

    private func bind(_ value: String?, at index: Int32, in statement: OpaquePointer) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
    }

    private func bind(_ value: Data, at index: Int32, in statement: OpaquePointer) {
        _ = value.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(value.count), SQLITE_TRANSIENT)
        }
    }

    private func bind(_ value: Double, at index: Int32, in statement: OpaquePointer) {
        sqlite3_bind_double(statement, index, value)
    }

    private func bind(_ value: Int, at index: Int32, in statement: OpaquePointer) {
        sqlite3_bind_int64(statement, index, sqlite3_int64(value))
    }

    private func data(at index: Int32, in statement: OpaquePointer) -> Data? {
        guard let bytes = sqlite3_column_blob(statement, index) else { return nil }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, index)))
    }

    private var errorMessage: String {
        String(cString: sqlite3_errmsg(database))
    }
}

enum SQLiteLocalDatabaseError: LocalizedError {
    case sqlite(message: String)

    var errorDescription: String? {
        switch self {
        case .sqlite(let message):
            return "Ошибка локальной базы: \(message)"
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

actor DatabaseLocalStorage: LocalStorage {
    private let database: LocalDatabase
    private let entity = "key_value"

    init(database: LocalDatabase) {
        self.database = database
    }

    func save<T: Codable>(_ value: T, for key: String) async throws {
        let data = try JSONEncoder().encode(value)
        try await database.saveRecord(data, entity: entity, id: key, syncStatus: .synced)
    }

    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        guard let data = try await database.loadRecord(Data.self, entity: entity, id: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    func removeValue(for key: String) async throws {
        try await database.deleteRecord(entity: entity, id: key, syncStatus: .synced)
    }
}

actor DatabaseExamSessionStore: ExamSessionStore {
    private let database: LocalDatabase
    private let entity = "exam_session"

    init(database: LocalDatabase) {
        self.database = database
    }

    func loadActiveSession() async throws -> ExamSession? {
        try await loadAllSessions().filter(\.status.isActive).sorted { $0.updatedAt > $1.updatedAt }.first
    }

    func loadActiveSession(datasetID: String) async throws -> ExamSession? {
        try await loadAllSessions()
            .filter { $0.datasetID == datasetID && $0.status.isActive }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    func loadAllSessions() async throws -> [ExamSession] {
        try await database.loadRecords(ExamSession.self, entity: entity)
    }

    func save(_ session: ExamSession) async throws {
        try await database.saveRecord(session, entity: entity, id: session.id, syncStatus: session.syncState.status)
    }

    func loadSession(id: ExamSession.ID) async throws -> ExamSession? {
        try await database.loadRecord(ExamSession.self, entity: entity, id: id)
    }

    func deleteSession(id: ExamSession.ID) async throws {
        try await database.deleteRecord(entity: entity, id: id, syncStatus: .synced)
    }
}
