import Foundation
import FirebaseFirestore
import Network

actor FirestoreOutboxSyncService: SyncServicing {
    private let database: LocalDatabase
    private let firestore: Firestore
    private var isSyncing = false

    init(database: LocalDatabase, firestore: Firestore = Firestore.firestore()) {
        self.database = database
        self.firestore = firestore
    }

    func scheduleSync(for scope: SyncScope) async {
        await syncPending()
    }

    func syncPending() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        while true {
            let mutations: [SyncMutation]
            do {
                mutations = try await database.pendingMutations(limit: 50)
            } catch {
                return
            }
            guard !mutations.isEmpty else { return }

            var madeProgress = false
            for mutation in mutations {
                do {
                    try await apply(mutation)
                    try await database.markMutationSynced(id: mutation.id)
                    madeProgress = true
                } catch {
                    try? await database.markMutationFailed(id: mutation.id, message: error.localizedDescription)
                }
            }
            guard madeProgress else { return }
        }
    }

    private func apply(_ mutation: SyncMutation) async throws {
        let reference = firestore.collection(mutation.collection).document(mutation.documentID)
        switch mutation.operation {
        case .delete:
            try await reference.delete()
        case .set:
            guard let payload = mutation.payload else { return }
            let document = try JSONDecoder().decode(SyncDocument.self, from: payload)
            try await reference.setData(document.firestoreData, merge: true)
        }
    }
}

final class SyncNetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "examup.sync.network")
    private let syncService: SyncServicing

    init(syncService: SyncServicing) {
        self.syncService = syncService
        monitor.pathUpdateHandler = { [syncService] path in
            guard path.status == .satisfied else { return }
            Task {
                await syncService.syncPending()
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

private extension SyncDocument {
    var firestoreData: [String: Any] {
        fields.mapValues(\.firestoreValue)
    }
}

private extension SyncFieldValue {
    var firestoreValue: Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        case .strings(let value):
            return value
        case .stringMap(let value):
            return value
        case .date(let value):
            return Timestamp(date: value)
        case .null:
            return NSNull()
        case .serverTimestamp:
            return FieldValue.serverTimestamp()
        }
    }
}
