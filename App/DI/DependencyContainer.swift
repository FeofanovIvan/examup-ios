import Foundation

struct DependencyContainer {
    let localDatabase: LocalDatabase
    let localStorage: LocalStorage
    let keyValueStorage: KeyValueStorage
    let examSessionStore: ExamSessionStore
    let educationalContentStore: EducationalContentStore
    let syncService: SyncServicing
    let syncNetworkMonitor: SyncNetworkMonitor
    let analytics: AnalyticsTracking
    let usageTracker: UsageTracking
    let permissionService: PermissionServicing
    let safeModeService: ExamSafeModeServicing
    let lifecycleService: AppLifecycleServicing
    let seedDataBootstrapService: SeedDataBootstrapServicing
    let subjectLibraryManager: SubjectLibraryManaging

    let authRepository: AuthRepository
    let userProfileRepository: UserProfileRepository
    let homeRepository: HomeRepository
    let tutorsRepository: TutorsRepository
    let calendarRepository: CalendarRepository
    let notificationsRepository: NotificationsRepository
    let settingsRepository: SettingsRepository
    let examRepository: ExamRepository

    static func live() -> DependencyContainer {
        let keyValueStorage = UserDefaultsKeyValueStorage()
        let localDatabase = SQLiteLocalDatabase()
        let localStorage = DatabaseLocalStorage(database: localDatabase)
        let examSessionStore = DatabaseExamSessionStore(database: localDatabase)
        let educationalContentStore = InMemoryEducationalContentStore()
        let syncService = FirestoreOutboxSyncService(database: localDatabase)
        let syncNetworkMonitor = SyncNetworkMonitor(syncService: syncService)
        let analytics = FirebaseAnalyticsTracker()
        let usageTracker = UserDefaultsUsageTracker(analytics: analytics)
        let permissionService = SystemPermissionService()
        let safeModeService = ExamSafeModeService(
            permissionService: permissionService,
            localDatabase: localDatabase,
            syncService: syncService
        )
        let authRepository = FirebaseAuthRepository()
        let lifecycleService = DefaultAppLifecycleService()
        let seedDataBootstrapService = SeedDataBootstrapService(
            fileProvider: SeedDataFileProvider(),
            decoder: EducationalContentSeedDecoder(),
            contentStore: educationalContentStore,
            stateStore: SeedImportStateStore(keyValueStorage: keyValueStorage)
        )
        let subjectLibraryManager = DefaultSubjectLibraryManager(
            decoder: EducationalContentSeedDecoder(),
            contentStore: educationalContentStore
        )

        return DependencyContainer(
            localDatabase: localDatabase,
            localStorage: localStorage,
            keyValueStorage: keyValueStorage,
            examSessionStore: examSessionStore,
            educationalContentStore: educationalContentStore,
            syncService: syncService,
            syncNetworkMonitor: syncNetworkMonitor,
            analytics: analytics,
            usageTracker: usageTracker,
            permissionService: permissionService,
            safeModeService: safeModeService,
            lifecycleService: lifecycleService,
            seedDataBootstrapService: seedDataBootstrapService,
            subjectLibraryManager: subjectLibraryManager,
            authRepository: authRepository,
            userProfileRepository: FirestoreUserProfileRepository(
                localDatabase: localDatabase,
                syncService: syncService
            ),
            homeRepository: DefaultHomeRepository(
                keyValueStorage: keyValueStorage,
                authRepository: authRepository,
                usageTracker: usageTracker
            ),
            tutorsRepository: DefaultTutorsRepository(contentStore: educationalContentStore),
            calendarRepository: DefaultCalendarRepository(
                examSessionStore: examSessionStore,
                contentStore: educationalContentStore
            ),
            notificationsRepository: FirestoreNotificationsRepository(),
            settingsRepository: DefaultSettingsRepository(),
            examRepository: DefaultExamRepository(
                examSessionStore: examSessionStore,
                resultRepository: FirestoreExamResultRepository(
                    localDatabase: localDatabase,
                    syncService: syncService
                ),
                usageTracker: usageTracker
            )
        )
    }
}
