import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    private let repository: HomeRepository

    @Published private(set) var dashboard = HomeDashboard.placeholder

    init(repository: HomeRepository) {
        self.repository = repository
    }

    func load() async {
        dashboard = (try? await repository.loadDashboard()) ?? .placeholder
    }

    func selectProgram(_ program: HomeStudyProgram) {
        dashboard = HomeDashboard(
            userName: dashboard.userName,
            userPublicID: dashboard.userPublicID,
            studyStreakDays: dashboard.studyStreakDays,
            startedExamCount: dashboard.startedExamCount,
            completedExamCount: dashboard.completedExamCount,
            savedAnswerCount: dashboard.savedAnswerCount,
            subjects: dashboard.subjects,
            programs: dashboard.programs,
            selectedProgram: program,
            blocks: HomeExamBlock.blocks(for: program)
        )

        Task {
            try? await repository.saveSelectedProgram(id: program.id)
        }
    }
}
