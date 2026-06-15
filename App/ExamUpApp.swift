import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ExamUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var coordinator = AppCoordinator(
        environment: AppEnvironment.bootstrap()
    )

    var body: some Scene {
        WindowGroup {
            RootNavigationView(coordinator: coordinator)
                .environmentObject(coordinator)
                .environment(\.appEnvironment, coordinator.environment)
        }
    }
}
