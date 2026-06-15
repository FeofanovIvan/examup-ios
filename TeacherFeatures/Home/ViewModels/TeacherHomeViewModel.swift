import Foundation

@MainActor
final class TeacherHomeViewModel: ObservableObject {
    private let repository: TeacherHomeRepository

    @Published private(set) var summary = TeacherHomeSummary.placeholder
    let sections = TeacherHomeSection.dashboard

    init(repository: TeacherHomeRepository) {
        self.repository = repository
    }

    func load() async {
        summary = (try? await repository.loadSummary()) ?? .placeholder
    }
}
