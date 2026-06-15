import Foundation

actor InMemoryLocalStorage: LocalStorage {
    private var values: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save<T: Codable>(_ value: T, for key: String) async throws {
        values[key] = try encoder.encode(value)
    }

    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        guard let data = values[key] else { return nil }
        return try decoder.decode(type, from: data)
    }

    func removeValue(for key: String) async throws {
        values[key] = nil
    }
}

final class InMemoryKeyValueStorage: KeyValueStorage {
    private var values: [String: String] = [:]

    func string(for key: String) -> String? {
        values[key]
    }

    func set(_ value: String?, for key: String) {
        values[key] = value
    }
}

final class UserDefaultsKeyValueStorage: KeyValueStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func string(for key: String) -> String? {
        defaults.string(forKey: key)
    }

    func set(_ value: String?, for key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

actor InMemoryExamSessionStore: ExamSessionStore {
    private var sessions: [ExamSession.ID: ExamSession] = [:]
    private var activeSessionID: ExamSession.ID?

    func loadActiveSession() async throws -> ExamSession? {
        guard let activeSessionID else { return nil }
        return sessions[activeSessionID]
    }

    func loadActiveSession(datasetID: String) async throws -> ExamSession? {
        sessions.values
            .filter { $0.datasetID == datasetID && $0.status.isActive }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    func loadAllSessions() async throws -> [ExamSession] {
        Array(sessions.values)
    }

    func save(_ session: ExamSession) async throws {
        sessions[session.id] = session
        if session.status.isActive {
            activeSessionID = session.id
        }
    }

    func loadSession(id: ExamSession.ID) async throws -> ExamSession? {
        sessions[id]
    }

    func deleteSession(id: ExamSession.ID) async throws {
        sessions[id] = nil
        if activeSessionID == id {
            activeSessionID = nil
        }
    }
}

actor UserDefaultsExamSessionStore: ExamSessionStore {
    private let defaults: UserDefaults
    private let key = "exam.sessions.v2"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadActiveSession() async throws -> ExamSession? {
        try loadSessions()
            .filter { $0.status.isActive }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    func loadActiveSession(datasetID: String) async throws -> ExamSession? {
        try loadSessions()
            .filter { $0.datasetID == datasetID && $0.status.isActive }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    func loadAllSessions() async throws -> [ExamSession] {
        try loadSessions()
    }

    func save(_ session: ExamSession) async throws {
        var sessions = try loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        try saveSessions(sessions)
    }

    func loadSession(id: ExamSession.ID) async throws -> ExamSession? {
        try loadSessions().first { $0.id == id }
    }

    func deleteSession(id: ExamSession.ID) async throws {
        var sessions = try loadSessions()
        sessions.removeAll { $0.id == id }
        try saveSessions(sessions)
    }

    private func loadSessions() throws -> [ExamSession] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try decoder.decode([ExamSession].self, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            #if DEBUG
            print("[ExamSessionStore] reset incompatible stored sessions: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    private func saveSessions(_ sessions: [ExamSession]) throws {
        let data = try encoder.encode(sessions)
        defaults.set(data, forKey: key)
    }
}
