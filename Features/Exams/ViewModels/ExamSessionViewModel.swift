import Foundation

@MainActor
final class ExamSessionViewModel: ObservableObject {
    private let repository: ExamRepository

    @Published private(set) var activeSession: ExamSession?

    init(repository: ExamRepository) {
        self.repository = repository
    }

    func loadActiveSession() async {
        activeSession = try? await repository.activeSession()
    }
}
