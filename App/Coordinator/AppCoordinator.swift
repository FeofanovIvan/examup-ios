import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    let environment: AppEnvironment

    @Published var authState: AuthState
    @Published var selectedRole: AppUserRole?
    @Published var selectedTab: AppTab = .home
    @Published var homePath = NavigationPath()
    @Published var tutorsPath = NavigationPath()
    @Published var calendarPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    @Published var teacherHomePath = NavigationPath()
    @Published private(set) var seedDataState: SeedDataLoadingState = .idle

    private var didBootstrapSeedData = false
    private var didBootstrapTeacherContent = false
    private var didRefreshAuthSession = false
    private var currentProfile: AppUserProfile?

    init(environment: AppEnvironment) {
        self.environment = environment
        self.authState = environment.sessionStore.currentAuthState
        self.selectedRole = environment.sessionStore.currentRole
    }

    func bootstrapSeedDataIfNeeded() async {
        guard !didBootstrapSeedData else {
            seedDataState = .ready
            return
        }
        didBootstrapSeedData = true
        seedDataState = .loading("Готовим задания")
        #if DEBUG
        print("[AppStartup] seed bootstrap requested")
        #endif
        await environment.dependencies.seedDataBootstrapService.bootstrapIfNeeded()
        seedDataState = .ready
        Task { [weak self] in
            await self?.updateInstalledStudentLibraries()
        }
        #if DEBUG
        print("[AppStartup] seed bootstrap ready")
        #endif
    }

    func bootstrapTeacherContentIfNeeded() async {
        guard !didBootstrapTeacherContent else {
            if case .loading = seedDataState { return }
            seedDataState = .ready
            return
        }
        didBootstrapTeacherContent = true
        seedDataState = .loading("Загружаем базу предмета")

        do {
            let profile = try await resolveCurrentProfile()
            guard profile.role == .teacher,
                  let subjectID = profile.teacherSubjectId,
                  let library = SubjectLibraryCatalog.library(subjectID: subjectID) else {
                throw TeacherContentBootstrapError.subjectUnavailable
            }

            seedDataState = .loading("Подготавливаем \(library.title.lowercased())")
            await environment.dependencies.seedDataBootstrapService
                .bootstrapBundledFreeContent(subjectID: subjectID)

            if try await environment.dependencies.subjectLibraryManager.importInstalled(library) {
                seedDataState = .ready
                Task { [weak self] in
                    do {
                        try await self?.environment.dependencies.subjectLibraryManager.updateIfNeeded(library)
                    } catch {
                        #if DEBUG
                        print("[AppStartup] teacher library update skipped subject=\(library.id): \(error.localizedDescription)")
                        #endif
                    }
                }
                return
            }

            seedDataState = .loading("Скачиваем \(library.title.lowercased())")
            try await environment.dependencies.subjectLibraryManager.download(library)
            seedDataState = .ready
        } catch {
            didBootstrapTeacherContent = false
            seedDataState = .failed(error.localizedDescription)
        }
    }

    func retryTeacherContentBootstrap() {
        didBootstrapTeacherContent = false
        seedDataState = .idle
    }

    func refreshAuthSessionIfNeeded() async {
        guard !didRefreshAuthSession else { return }
        didRefreshAuthSession = true
        await environment.dependencies.syncService.syncPending()

        do {
            guard let user = try await environment.dependencies.authRepository.currentUser() else {
                authState = .unauthenticated
                selectedRole = nil
                environment.sessionStore.currentAuthState = .unauthenticated
                environment.sessionStore.currentRole = nil
                return
            }

            guard let profile = try await environment.dependencies.userProfileRepository.loadProfile(userID: user.id) else {
                try? environment.dependencies.authRepository.signOut()
                authState = .unauthenticated
                selectedRole = nil
                environment.sessionStore.currentAuthState = .unauthenticated
                environment.sessionStore.currentRole = nil
                return
            }

            selectedRole = profile.role
            currentProfile = profile
            authState = .authenticated
            environment.sessionStore.currentRole = profile.role
            environment.sessionStore.currentAuthState = .authenticated
        } catch {
            authState = .unauthenticated
            selectedRole = nil
            environment.sessionStore.currentAuthState = .unauthenticated
            environment.sessionStore.currentRole = nil
        }
    }

    func selectRole(_ role: AppUserRole) {
        selectedRole = role
        environment.sessionStore.currentRole = role
        resetNavigation()
    }

    func clearSelectedRole() {
        selectedRole = nil
        environment.sessionStore.currentRole = nil
        resetNavigation()
    }

    func completeAuthentication() {
        authState = .authenticated
        didRefreshAuthSession = false
        environment.sessionStore.currentAuthState = .authenticated
    }

    func signOut() {
        try? environment.dependencies.authRepository.signOut()
        authState = .unauthenticated
        selectedRole = nil
        seedDataState = .idle
        didBootstrapSeedData = false
        didBootstrapTeacherContent = false
        currentProfile = nil
        environment.sessionStore.currentAuthState = .unauthenticated
        environment.sessionStore.currentRole = nil
        resetNavigation()
    }

    func resetNavigation() {
        selectedTab = .home
        homePath = NavigationPath()
        tutorsPath = NavigationPath()
        calendarPath = NavigationPath()
        settingsPath = NavigationPath()
        teacherHomePath = NavigationPath()
    }

    private func resolveCurrentProfile() async throws -> AppUserProfile {
        if let currentProfile { return currentProfile }
        guard let user = try await environment.dependencies.authRepository.currentUser(),
              let profile = try await environment.dependencies.userProfileRepository.loadProfile(userID: user.id) else {
            throw TeacherContentBootstrapError.profileUnavailable
        }
        currentProfile = profile
        return profile
    }

    private func updateInstalledStudentLibraries() async {
        let installedLibraries = await environment.dependencies.subjectLibraryManager
            .loadStatuses()
            .filter(\.isDownloaded)
            .map(\.library)

        for library in installedLibraries {
            do {
                try await environment.dependencies.subjectLibraryManager.updateIfNeeded(library)
            } catch {
                #if DEBUG
                print("[AppStartup] student library update skipped subject=\(library.id): \(error.localizedDescription)")
                #endif
            }
        }
    }
}

enum SeedDataLoadingState: Equatable {
    case idle
    case loading(String)
    case ready
    case failed(String)
}

private enum TeacherContentBootstrapError: LocalizedError {
    case profileUnavailable
    case subjectUnavailable

    var errorDescription: String? {
        switch self {
        case .profileUnavailable:
            return "Не удалось загрузить профиль преподавателя."
        case .subjectUnavailable:
            return "В профиле преподавателя не выбран доступный предмет."
        }
    }
}
