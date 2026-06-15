import SwiftUI

struct TeacherAppShellView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var notificationsViewModel: NotificationsViewModel

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _notificationsViewModel = StateObject(
            wrappedValue: NotificationsViewModel(
                repository: coordinator.environment.dependencies.notificationsRepository
            )
        )
    }

    var body: some View {
        NavigationStack(path: $coordinator.teacherHomePath) {
            TeacherHomeView(
                viewModel: TeacherHomeViewModel(
                    repository: FirestoreTeacherHomeRepository()
                ),
                notificationsViewModel: notificationsViewModel,
                contentStore: coordinator.environment.dependencies.educationalContentStore,
                seedDataBootstrapService: coordinator.environment.dependencies.seedDataBootstrapService,
                assignmentRepository: FirestoreTeacherAssignmentRepository(
                    localDatabase: coordinator.environment.dependencies.localDatabase,
                    syncService: coordinator.environment.dependencies.syncService
                ),
                studentsRepository: DefaultTeacherStudentsRepository(
                    localDatabase: coordinator.environment.dependencies.localDatabase
                ),
                onSignOut: coordinator.signOut
            )
        }
        .task {
            await notificationsViewModel.listenForUpdates()
        }
    }
}
