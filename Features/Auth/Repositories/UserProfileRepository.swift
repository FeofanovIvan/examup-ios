import Foundation
import FirebaseFirestore

protocol UserProfileRepository {
    func saveProfile(_ profile: AppUserProfile) async throws
    func loadProfile(userID: String) async throws -> AppUserProfile?
}

struct DefaultUserProfileRepository: UserProfileRepository {
    func saveProfile(_ profile: AppUserProfile) async throws {}

    func loadProfile(userID: String) async throws -> AppUserProfile? {
        nil
    }
}

struct FirestoreUserProfileRepository: UserProfileRepository {
    private let database = Firestore.firestore()
    private let localDatabase: LocalDatabase
    private let syncService: SyncServicing

    init(localDatabase: LocalDatabase, syncService: SyncServicing) {
        self.localDatabase = localDatabase
        self.syncService = syncService
    }

    func loadProfile(userID: String) async throws -> AppUserProfile? {
        if let local = try await localDatabase.loadRecord(AppUserProfile.self, entity: "account", id: userID) {
            return local
        }

        let snapshot = try await database
            .collection("accounts")
            .document(userID)
            .getDocument()

        guard let data = snapshot.data() else { return nil }
        let roleRawValue = data["role"] as? String ?? AppUserRole.student.rawValue
        let role = AppUserRole(rawValue: roleRawValue) ?? .student
        let publicId = data["publicToken"] as? String ?? AppUserIDGenerator.sixDigitID(from: userID)

        let profile = AppUserProfile(
            id: userID,
            publicId: publicId,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            role: role,
            studentId: role == .student ? publicId : nil,
            teacherSubjectId: data["teacherSubjectId"] as? String,
            teacherSubjectTitle: data["teacherSubjectTitle"] as? String
        )
        try await localDatabase.saveRecord(profile, entity: "account", id: userID, syncStatus: .synced)
        return profile
    }

    func saveProfile(_ profile: AppUserProfile) async throws {
        try await localDatabase.saveRecord(profile, entity: "account", id: profile.id, syncStatus: .pending)
        try await enqueueAccount(profile)

        if profile.role == .teacher {
            try await enqueueTeacher(profile)
        } else {
            try await enqueueStudent(profile)
        }
        await syncService.scheduleSync(for: .auth)
    }

    private func enqueueAccount(_ profile: AppUserProfile) async throws {
        let document = SyncDocument(fields: [
            "uid": .string(profile.id),
            "publicToken": .string(profile.publicId),
            "name": .string(profile.name),
            "email": .string(profile.email),
            "role": .string(profile.role.rawValue),
            "teacherSubjectId": profile.teacherSubjectId.map(SyncFieldValue.string) ?? .null,
            "teacherSubjectTitle": profile.teacherSubjectTitle.map(SyncFieldValue.string) ?? .null,
            "updatedAt": .serverTimestamp
        ])
        try await localDatabase.enqueue(
            SyncMutation(collection: "accounts", documentID: profile.id, operation: .set, payload: try document.encoded())
        )
    }

    private func enqueueTeacher(_ profile: AppUserProfile) async throws {
        let document = SyncDocument(fields: [
            "uid": .string(profile.id),
            "publicToken": .string(profile.publicId),
            "name": .string(profile.name),
            "email": .string(profile.email),
            "subjectId": .string(profile.teacherSubjectId ?? ""),
            "subjectTitle": .string(profile.teacherSubjectTitle ?? ""),
            "updatedAt": .serverTimestamp
        ])
        try await localDatabase.enqueue(
            SyncMutation(collection: "teachers", documentID: profile.id, operation: .set, payload: try document.encoded())
        )
    }

    private func enqueueStudent(_ profile: AppUserProfile) async throws {
        let document = SyncDocument(fields: [
            "uid": .string(profile.id),
            "publicToken": .string(profile.publicId),
            "name": .string(profile.name),
            "email": .string(profile.email),
            "updatedAt": .serverTimestamp
        ])
        try await localDatabase.enqueue(
            SyncMutation(collection: "students", documentID: profile.id, operation: .set, payload: try document.encoded())
        )
    }
}
