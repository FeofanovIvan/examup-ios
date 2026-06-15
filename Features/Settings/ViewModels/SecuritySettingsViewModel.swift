import Foundation

@MainActor
final class SecuritySettingsViewModel: ObservableObject {
    private let repository: SecuritySettingsRepository

    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    var email: String { repository.currentEmail() ?? "" }

    init(repository: SecuritySettingsRepository) {
        self.repository = repository
    }

    func sendPasswordReset() async {
        guard !isSending else { return }
        isSending = true
        errorMessage = nil
        successMessage = nil
        do {
            try await repository.sendPasswordReset()
            successMessage = "Письмо со ссылкой отправлено на \(email)"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }
}
