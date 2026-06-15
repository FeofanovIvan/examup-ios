import Foundation

@MainActor
final class ProfileSettingsViewModel: ObservableObject {
    private let repository: ProfileSettingsRepository

    @Published var displayName = ""
    @Published var email = ""
    @Published var isEmailVerified = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false

    var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    init(repository: ProfileSettingsRepository) {
        self.repository = repository
    }

    func load() async {
        guard let data = try? await repository.load() else { return }
        displayName = data.displayName
        email = data.email
        isEmailVerified = data.isEmailVerified
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await repository.save(displayName: displayName)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
