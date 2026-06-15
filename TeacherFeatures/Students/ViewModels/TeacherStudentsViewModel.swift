import Foundation

@MainActor
final class TeacherStudentsViewModel: ObservableObject {
    private let repository: TeacherStudentsRepository

    @Published private(set) var students: [TeacherLocalStudent] = []
    @Published private(set) var isLoading = false
    @Published var selectedClass = ""
    @Published var errorMessage: String?

    init(repository: TeacherStudentsRepository) {
        self.repository = repository
    }

    var classes: [String] {
        Array(Set(students.map(\.className).filter { !$0.isEmpty })).sorted()
    }

    var filteredStudents: [TeacherLocalStudent] {
        selectedClass.isEmpty ? students : students.filter { $0.className == selectedClass }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            students = try await repository.loadStudents()
            if !selectedClass.isEmpty, !classes.contains(selectedClass) {
                selectedClass = ""
            }
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось загрузить локальный список учеников"
        }
    }

    func delete(_ student: TeacherLocalStudent) async {
        do {
            try await repository.deleteStudent(id: student.id)
            await load()
        } catch {
            errorMessage = "Не удалось удалить ученика"
        }
    }
}
