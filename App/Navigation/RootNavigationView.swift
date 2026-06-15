import SwiftUI

struct RootNavigationView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            switch coordinator.authState {
            case .unauthenticated:
                PreAuthFlowView(coordinator: coordinator)
            case .authenticated:
                switch coordinator.selectedRole {
                case .student?:
                    switch coordinator.seedDataState {
                    case .ready:
                        StudentAppShellView(coordinator: coordinator)
                    case .idle, .loading, .failed:
                        AppLoadingView(state: coordinator.seedDataState)
                            .task {
                                await coordinator.bootstrapSeedDataIfNeeded()
                            }
                    }
                case .teacher?:
                    switch coordinator.seedDataState {
                    case .ready:
                        TeacherAppShellView(coordinator: coordinator)
                    case .idle, .loading:
                        AppLoadingView(state: coordinator.seedDataState)
                            .task {
                                await coordinator.bootstrapTeacherContentIfNeeded()
                            }
                    case .failed:
                        AppLoadingView(
                            state: coordinator.seedDataState,
                            retryAction: {
                                coordinator.retryTeacherContentBootstrap()
                                Task { await coordinator.bootstrapTeacherContentIfNeeded() }
                            }
                        )
                    }
                case nil:
                    PreAuthFlowView(coordinator: coordinator)
                }
            }
        }
        .task {
            await coordinator.refreshAuthSessionIfNeeded()
        }
    }
}

private struct AppLoadingView: View {
    let state: SeedDataLoadingState
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            Image("auth")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Добро пожаловать!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Text(statusText)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: "687083"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if case .failed = state, let retryAction {
                Button("Повторить загрузку", action: retryAction)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "7257F4"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color(hex: "7257F4"))
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FBFCFF"))
    }

    private var statusText: String {
        switch state {
        case .idle:
            return "Подготавливаем приложение"
        case .loading(let message):
            return message
        case .ready:
            return "Готово"
        case .failed(let message):
            return message
        }
    }
}

private struct PreAuthFlowView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack {
            if let selectedRole = coordinator.selectedRole {
                WelcomeView(
                    viewModel: WelcomeViewModel(
                        repository: coordinator.environment.dependencies.authRepository,
                        userProfileRepository: coordinator.environment.dependencies.userProfileRepository
                    ),
                    selectedRole: selectedRole,
                    onContinue: coordinator.completeAuthentication,
                    onChangeRole: coordinator.clearSelectedRole
                )
            } else {
                RoleSelectionView(onRoleSelected: coordinator.selectRole)
            }
        }
    }
}
