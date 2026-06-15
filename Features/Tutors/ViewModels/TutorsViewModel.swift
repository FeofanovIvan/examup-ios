import Foundation

@MainActor
final class TutorsViewModel: ObservableObject {
    private let repository: TutorsRepository

    @Published var filters = TutorFilters()
    @Published var tutorID = ""
    @Published var email = ""
    @Published var selectedSubject = Subject.placeholders[0]
    @Published private(set) var tutors: [TutorConnection] = []
    @Published private(set) var assignments: [TutorAssignment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    let subjects = Array(Subject.placeholders.prefix(3))

    init(repository: TutorsRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let loadedTutors = repository.loadTutors(filters: filters)
            async let loadedAssignments = repository.loadAssignments(filters: filters)
            tutors = try await loadedTutors
            assignments = try await loadedAssignments
        } catch {
            errorMessage = error.localizedDescription
            tutors = []
            assignments = []
        }
    }

    func addTutor() async {
        let normalizedTutorID = tutorID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedTutorID.isEmpty else {
            errorMessage = "Введите ID репетитора."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await repository.addTutor(
                AddTutorRequest(
                    tutorID: normalizedTutorID,
                    email: "",
                    subject: selectedSubject
                )
            )
            tutorID = ""
            successMessage = "Запрос репетитору отправлен."
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func inviteTutor() async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.contains("@") else {
            errorMessage = "Введите корректный email репетитора."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await repository.inviteTutor(email: normalizedEmail)
            email = ""
            successMessage = "Приглашение отправлено."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeTutor(_ tutor: TutorConnection) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await repository.removeTutor(tutor)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareAssignment(_ assignment: TutorAssignment) async -> ExamConstructorStartContext? {
        guard !assignment.isSubmitted else {
            errorMessage = "Это задание уже сдано."
            return nil
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            return try await repository.prepareAssignmentExam(id: assignment.id)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func submitAssignment(id: String) async {
        do {
            try await repository.submitAssignment(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
