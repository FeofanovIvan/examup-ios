import SwiftUI

struct StudentAppShellView: View {
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
        TabView(selection: $coordinator.selectedTab) {
            NavigationStack(path: $coordinator.homePath) {
                HomeView(
                    viewModel: HomeViewModel(
                        repository: coordinator.environment.dependencies.homeRepository
                    ),
                    notificationsViewModel: notificationsViewModel,
                    subjectLibraryManager: coordinator.environment.dependencies.subjectLibraryManager,
                    onExamBlockSelected: { block in
                        if let category = block.examCategory,
                           category == .ege || category == .oge || category == .vpr {
                            coordinator.homePath.append(
                                HomeRoute.examConsent(
                                    ExamStartContext(
                                        title: block.title,
                                        category: category,
                                        datasetID: block.datasetID
                                    )
                                )
                            )
                        } else if block.examCategory == .constructor,
                                  let datasetID = block.datasetID {
                            coordinator.homePath.append(HomeRoute.examConstructor(datasetID))
                        }
                    },
                    onNotificationsTap: {
                        coordinator.homePath.append(HomeRoute.notifications)
                    },
                    onSubjectDownloadRequested: {
                        coordinator.homePath.append(HomeRoute.subjectLibraries)
                    }
                )
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .subject:
                        PlaceholderBlock(title: "Предмет", subtitle: "Раздел будет подключен позже")
                    case .subjectLibraries:
                        SubjectLibrariesView(
                            viewModel: SubjectLibrariesViewModel(
                                manager: coordinator.environment.dependencies.subjectLibraryManager
                            ),
                            onBack: {
                                if !coordinator.homePath.isEmpty {
                                    coordinator.homePath.removeLast()
                                }
                            }
                        )
                        .navigationBarBackButtonHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                    case .notifications:
                        NotificationsView(
                            viewModel: notificationsViewModel,
                            onBack: {
                                if !coordinator.homePath.isEmpty {
                                    coordinator.homePath.removeLast()
                                }
                            }
                        )
                    case .examCategory(let category):
                        if category == .ege {
                            ExamWorkspaceView(
                                viewModel: ExamWorkspaceViewModel(
                                    datasetID: SeedDatasetID.mathEGEBase.rawValue,
                                    contentStore: coordinator.environment.dependencies.educationalContentStore,
                                    examRepository: coordinator.environment.dependencies.examRepository,
                                    safeModeService: coordinator.environment.dependencies.safeModeService
                                )
                            )
                        } else {
                            ExamSessionPlaceholderView(
                                viewModel: ExamSessionViewModel(
                                    repository: coordinator.environment.dependencies.examRepository
                                )
                            )
                        }
                    case .examConsent(let context):
                        ExamConsentView(context: context) { consent in
                            if let datasetID = context.datasetID {
                                coordinator.homePath.append(HomeRoute.examDataset(datasetID, consent))
                            } else {
                                coordinator.homePath.append(HomeRoute.examCategory(context.category))
                            }
                        }
                    case .examDataset(let datasetID, let consent):
                        ExamWorkspaceView(
                            viewModel: ExamWorkspaceViewModel(
                                datasetID: datasetID,
                                proctoringConsent: consent,
                                contentStore: coordinator.environment.dependencies.educationalContentStore,
                                examRepository: coordinator.environment.dependencies.examRepository,
                                safeModeService: coordinator.environment.dependencies.safeModeService
                            ),
                            onFinished: {
                                coordinator.homePath = NavigationPath()
                            }
                        )
                    case .examConstructor(let datasetID):
                        ExamConstructorView(
                            viewModel: ExamConstructorViewModel(
                                datasetID: datasetID,
                                contentStore: coordinator.environment.dependencies.educationalContentStore
                            ),
                            onStart: { context in
                                coordinator.homePath.append(HomeRoute.customExamConsent(context))
                            }
                        )
                    case .customExamConsent(let context):
                        ExamConsentView(
                            context: ExamStartContext(
                                title: context.title,
                                category: .constructor,
                                datasetID: context.datasetID
                            )
                        ) { consent in
                            coordinator.homePath.append(HomeRoute.customExam(context, consent))
                        }
                    case .customExam(let context, let consent):
                        ExamWorkspaceView(
                            viewModel: ExamWorkspaceViewModel(
                                datasetID: context.datasetID,
                                customTitle: context.title,
                                customTaskIDs: context.taskIDs,
                                durationSeconds: context.durationSeconds,
                                proctoringConsent: consent,
                                contentStore: coordinator.environment.dependencies.educationalContentStore,
                                examRepository: coordinator.environment.dependencies.examRepository,
                                safeModeService: coordinator.environment.dependencies.safeModeService
                            ),
                            onFinished: {
                                coordinator.homePath = NavigationPath()
                            }
                        )
                    }
                }
            }
            .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
            .tag(AppTab.home)

            NavigationStack(path: $coordinator.tutorsPath) {
                TutorsView(
                    viewModel: TutorsViewModel(
                        repository: coordinator.environment.dependencies.tutorsRepository
                    ),
                    notificationsViewModel: notificationsViewModel,
                    onNotificationsTap: {
                        coordinator.tutorsPath.append(TutorsRoute.notifications)
                    },
                    onAssignmentSelected: { context in
                        coordinator.tutorsPath.append(TutorsRoute.assignmentConsent(context))
                    }
                )
                .navigationDestination(for: TutorsRoute.self) { route in
                    switch route {
                    case .assignmentConsent(let context):
                        ExamConsentView(
                            context: ExamStartContext(
                                title: context.title,
                                category: .constructor,
                                datasetID: context.datasetID
                            ),
                            requiresSafeMode: true
                        ) { consent in
                            coordinator.tutorsPath.append(TutorsRoute.assignmentExam(context, consent))
                        }
                    case .assignmentExam(let context, let consent):
                        ExamWorkspaceView(
                            viewModel: ExamWorkspaceViewModel(
                                datasetID: context.datasetID,
                                customTitle: context.title,
                                customTaskIDs: context.taskIDs,
                                durationSeconds: context.durationSeconds,
                                proctoringConsent: consent,
                                contentStore: coordinator.environment.dependencies.educationalContentStore,
                                examRepository: coordinator.environment.dependencies.examRepository,
                                safeModeService: coordinator.environment.dependencies.safeModeService
                            ),
                            onSubmitted: {
                                if let assignmentID = context.assignmentID {
                                    try? await coordinator.environment.dependencies.tutorsRepository.submitAssignment(id: assignmentID)
                                }
                            },
                            onFinished: {
                                coordinator.tutorsPath = NavigationPath()
                            }
                        )
                    case .notifications:
                        NotificationsView(
                            viewModel: notificationsViewModel,
                            onBack: {
                                if !coordinator.tutorsPath.isEmpty {
                                    coordinator.tutorsPath.removeLast()
                                }
                            }
                        )
                    }
                }
            }
            .tabItem { Label(AppTab.tutors.title, systemImage: AppTab.tutors.systemImage) }
            .tag(AppTab.tutors)

            NavigationStack(path: $coordinator.calendarPath) {
                CalendarFeatureView(
                    viewModel: CalendarViewModel(
                        repository: coordinator.environment.dependencies.calendarRepository
                    )
                )
            }
            .tabItem { Label(AppTab.calendar.title, systemImage: AppTab.calendar.systemImage) }
            .tag(AppTab.calendar)

            NavigationStack(path: $coordinator.settingsPath) {
                SettingsView(
                    viewModel: SettingsViewModel(
                        repository: coordinator.environment.dependencies.settingsRepository
                    ),
                    onNavigate: { route in
                        coordinator.settingsPath.append(route)
                    },
                    onSignOut: coordinator.signOut
                )
                .navigationDestination(for: SettingsRoute.self) { route in
                    switch route {
                    case .profile:
                        ProfileSettingsView(
                            viewModel: ProfileSettingsViewModel(
                                repository: FirebaseProfileSettingsRepository()
                            ),
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .security:
                        SecuritySettingsView(
                            viewModel: SecuritySettingsViewModel(
                                repository: FirebaseSecuritySettingsRepository()
                            ),
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .notifications:
                        NotificationsSettingsView(
                            viewModel: NotificationsSettingsViewModel(),
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .subjects:
                        SubjectLibrariesView(
                            viewModel: SubjectLibrariesViewModel(
                                manager: coordinator.environment.dependencies.subjectLibraryManager
                            ),
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .examSettings:
                        ExamSettingsView(
                            viewModel: ExamSettingsViewModel(),
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .deadlines:
                        DeadlinesSettingsView(
                            viewModel: DeadlinesSettingsViewModel(),
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .support:
                        SupportView(
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    case .about:
                        AboutView(
                            onBack: { coordinator.settingsPath.removeLast() }
                        )
                    }
                }
            }
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage) }
            .tag(AppTab.settings)
        }
        .onChange(of: coordinator.selectedTab) { previousTab, selectedTab in
            guard selectedTab == .tutors, previousTab != .tutors else { return }
            coordinator.tutorsPath = NavigationPath()
        }
        .task {
            await notificationsViewModel.listenForUpdates()
        }
    }
}
