import Foundation
import FirebaseAuth

protocol ProfileSettingsRepository {
    func load() async throws -> ProfileSettingsData
    func save(displayName: String) async throws
}

struct ProfileSettingsData: Equatable {
    let displayName: String
    let email: String
    let isEmailVerified: Bool
}

struct FirebaseProfileSettingsRepository: ProfileSettingsRepository {
    func load() async throws -> ProfileSettingsData {
        guard let user = Auth.auth().currentUser else {
            throw ProfileSettingsError.notAuthenticated
        }
        let name = user.displayName?.isEmpty == false
            ? user.displayName!
            : user.email?.components(separatedBy: "@").first ?? "Пользователь"
        return ProfileSettingsData(
            displayName: name,
            email: user.email ?? "",
            isEmailVerified: user.isEmailVerified
        )
    }

    func save(displayName: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw ProfileSettingsError.notAuthenticated
        }
        let request = user.createProfileChangeRequest()
        request.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        try await request.commitChanges()
    }
}

enum ProfileSettingsError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Пользователь не авторизован"
        }
    }
}
