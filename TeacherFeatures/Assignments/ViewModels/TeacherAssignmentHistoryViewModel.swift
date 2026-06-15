import Foundation

@MainActor
final class TeacherAssignmentHistoryViewModel: ObservableObject {
    private let repository: TeacherAssignmentHistoryRepository
    private let studentID: String?

    @Published private(set) var assignments: [TeacherAssignmentHistoryItem] = []
    @Published var filter: TeacherAssignmentHistoryFilter = .all
    @Published var resultReport: ExamResultReport?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    init(repository: TeacherAssignmentHistoryRepository, studentID: String? = nil) {
        self.repository = repository
        self.studentID = studentID
    }

    var filteredAssignments: [TeacherAssignmentHistoryItem] {
        let studentAssignments = studentID.map { selectedID in
            assignments.filter { $0.studentID == selectedID }
        } ?? assignments

        switch filter {
        case .all: return studentAssignments
        case .pending: return studentAssignments.filter { !$0.isSubmitted }
        case .submitted: return studentAssignments.filter(\.isSubmitted)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            assignments = try await repository.loadAssignments()
        } catch {
            errorMessage = "Не удалось загрузить историю заданий"
        }
    }

    func showResult(for item: TeacherAssignmentHistoryItem) {
        Task {
            resultReport = try? await repository.loadResult(for: item)
            if resultReport == nil {
                errorMessage = "Результат пока не синхронизирован"
            }
        }
    }
}
