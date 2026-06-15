import Foundation
import FirebaseAuth

protocol SecuritySettingsRepository {
    func sendPasswordReset() async throws
    func currentEmail() -> String?
}

struct FirebaseSecuritySettingsRepository: SecuritySettingsRepository {
    func sendPasswordReset() async throws {
        guard let email = Auth.auth().currentUser?.email, !email.isEmpty else {
            throw SecuritySettingsError.noEmail
        }
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func currentEmail() -> String? {
        Auth.auth().currentUser?.email
    }
}

enum SecuritySettingsError: LocalizedError {
    case noEmail

    var errorDescription: String? {
        switch self {
        case .noEmail: return "Email аккаунта не найден"
        }
    }
}
