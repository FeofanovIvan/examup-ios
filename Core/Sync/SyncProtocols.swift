import Foundation

enum SyncStatus: String, Codable, Equatable {
    case idle
    case pending
    case syncing
    case failed
    case synced
}

enum SyncOperation: String, Codable, Equatable, Sendable {
    case set
    case delete
}

struct SyncMutation: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let collection: String
    let documentID: String
    let operation: SyncOperation
    let payload: Data?
    let createdAt: Date
    var attemptCount: Int
    var lastError: String?

    init(
        id: String = UUID().uuidString,
        collection: String,
        documentID: String,
        operation: SyncOperation,
        payload: Data? = nil,
        createdAt: Date = Date(),
        attemptCount: Int = 0,
        lastError: String? = nil
    ) {
        self.id = id
        self.collection = collection
        self.documentID = documentID
        self.operation = operation
        self.payload = payload
        self.createdAt = createdAt
        self.attemptCount = attemptCount
        self.lastError = lastError
    }
}

enum SyncFieldValue: Codable, Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case strings([String])
    case stringMap([String: String])
    case date(Date)
    case null
    case serverTimestamp
}

struct SyncDocument: Codable, Equatable, Sendable {
    let fields: [String: SyncFieldValue]

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

struct SyncState: Codable, Equatable {
    var status: SyncStatus
    var lastSyncedAt: Date?
    var errorMessage: String?

    static let idle = SyncState(status: .idle, lastSyncedAt: nil, errorMessage: nil)
}

protocol SyncServicing {
    func scheduleSync(for scope: SyncScope) async
    func syncPending() async
}

enum SyncScope: String, Codable, Hashable {
    case auth
    case home
    case tutors
    case calendar
    case settings
    case exams
}

struct NoOpSyncService: SyncServicing {
    func scheduleSync(for scope: SyncScope) async {}
    func syncPending() async {}
}
