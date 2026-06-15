import SwiftUI

struct AppEnvironment {
    let dependencies: DependencyContainer
    let sessionStore: AppSessionStore
    let theme: AppTheme

    static func bootstrap() -> AppEnvironment {
        let dependencies = DependencyContainer.live()

        return AppEnvironment(
            dependencies: dependencies,
            sessionStore: UserDefaultsAppSessionStore(),
            theme: .default
        )
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.bootstrap()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
