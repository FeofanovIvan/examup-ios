import Foundation
import FirebaseAuth

protocol AuthRepository {
    func currentUser() async throws -> AuthUser?
    func signIn(email: String, password: String) async throws -> AuthUser
    func register(name: String, email: String, password: String) async throws -> AuthUser
    func signOut() throws
}

struct DefaultAuthRepository: AuthRepository {
    func currentUser() async throws -> AuthUser? {
        nil
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        AuthUser(id: UUID().uuidString, email: email, displayName: nil, isEmailVerified: false)
    }

    func register(name: String, email: String, password: String) async throws -> AuthUser {
        AuthUser(id: UUID().uuidString, email: email, displayName: name, isEmailVerified: false)
    }

    func signOut() throws {}
}

struct FirebaseAuthRepository: AuthRepository {
    /// Waits for Firebase to restore its persisted session from Keychain before returning
    /// the current user. Calling `Auth.auth().currentUser` synchronously on launch returns
    /// nil because Firebase restores the token asynchronously — this method uses
    /// addStateDidChangeListener to get the first authoritative auth state event instead.
    func currentUser() async throws -> AuthUser? {
        try await withCheckedThrowingContinuation { continuation in
            var handle: AuthStateDidChangeListenerHandle?
            handle = Auth.auth().addStateDidChangeListener { _, user in
                if let handle { Auth.auth().removeStateDidChangeListener(handle) }
                continuation.resume(returning: user.map(AuthUser.init(firebaseUser:)))
            }
        }
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthUser(firebaseUser: result.user)
    }

    func register(name: String, email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        return AuthUser(firebaseUser: result.user)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

private extension AuthUser {
    init(firebaseUser: User) {
        self.init(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            isEmailVerified: firebaseUser.isEmailVerified
        )
    }
}
