import Foundation

struct AuthUser: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let displayName: String?
    let isEmailVerified: Bool
}

enum AuthStep: String, CaseIterable, Identifiable {
    case welcome
    case login
    case register
    case emailVerification
    case initialSetup

    var id: String { rawValue }
}
