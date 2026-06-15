import Foundation

protocol AppSessionStore: AnyObject {
    var currentAuthState: AuthState { get set }
    var currentRole: AppUserRole? { get set }
}

final class InMemoryAppSessionStore: AppSessionStore {
    var currentAuthState: AuthState = .unauthenticated
    var currentRole: AppUserRole?
}

final class UserDefaultsAppSessionStore: AppSessionStore {
    private enum Keys {
        static let authState = "app.session.auth_state"
        static let role = "app.session.role"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentAuthState: AuthState {
        get {
            guard let rawValue = defaults.string(forKey: Keys.authState) else {
                return .unauthenticated
            }
            return AuthState(rawValue: rawValue) ?? .unauthenticated
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.authState)
        }
    }

    var currentRole: AppUserRole? {
        get {
            guard let rawValue = defaults.string(forKey: Keys.role) else {
                return nil
            }
            return AppUserRole(rawValue: rawValue)
        }
        set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: Keys.role)
            } else {
                defaults.removeObject(forKey: Keys.role)
            }
        }
    }
}
