import Foundation

protocol HomeRepository {
    func loadDashboard() async throws -> HomeDashboard
    func saveSelectedProgram(id: HomeStudyProgram.ID) async throws
}

struct DefaultHomeRepository: HomeRepository {
    private let keyValueStorage: KeyValueStorage
    private let authRepository: AuthRepository
    private let usageTracker: UsageTracking
    private let selectedProgramKey = "home.selected_study_program"

    init(keyValueStorage: KeyValueStorage, authRepository: AuthRepository, usageTracker: UsageTracking) {
        self.keyValueStorage = keyValueStorage
        self.authRepository = authRepository
        self.usageTracker = usageTracker
    }

    func loadDashboard() async throws -> HomeDashboard {
        let programs = HomeStudyProgram.all
        let storedID = keyValueStorage.string(for: selectedProgramKey)
        let normalizedStoredID = storedID == "math_base" || storedID == "math_profile" ? HomeStudyProgram.math.id : storedID
        let selectedProgram = programs.first { $0.id == normalizedStoredID } ?? .defaultProgram
        let subjects = programs.map(\.subject)
        let user = try await authRepository.currentUser()
        let userName = Self.displayName(from: user)
        let publicID = user.map { AppUserIDGenerator.sixDigitID(from: $0.id) } ?? "000000"
        let usage = await usageTracker.loadUsageSummary()

        return HomeDashboard(
            userName: userName,
            userPublicID: publicID,
            studyStreakDays: usage.currentStreakDays,
            startedExamCount: usage.startedExamCount,
            completedExamCount: usage.completedExamCount,
            savedAnswerCount: usage.savedAnswerCount,
            subjects: subjects,
            programs: programs,
            selectedProgram: selectedProgram,
            blocks: HomeExamBlock.blocks(for: selectedProgram)
        )
    }

    func saveSelectedProgram(id: HomeStudyProgram.ID) async throws {
        keyValueStorage.set(id, for: selectedProgramKey)
    }

    private static func displayName(from user: AuthUser?) -> String {
        let name = user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return name
        }

        let emailPrefix = user?.email.components(separatedBy: "@").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let emailPrefix, !emailPrefix.isEmpty {
            return emailPrefix
        }

        return "Пользователь"
    }
}
