import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
    let repository: AuthRepository
    let userProfileRepository: UserProfileRepository

    @Published private(set) var steps = AuthStep.allCases

    init(repository: AuthRepository, userProfileRepository: UserProfileRepository) {
        self.repository = repository
        self.userProfileRepository = userProfileRepository
    }
}

@MainActor
final class AuthPlaceholderViewModel: ObservableObject {
    let title: String

    init(title: String) {
        self.title = title
    }
}

@MainActor
final class LoginViewModel: ObservableObject {
    private let repository: AuthRepository
    private let userProfileRepository: UserProfileRepository
    private let selectedRole: AppUserRole

    @Published var email = ""
    @Published var password = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(
        repository: AuthRepository,
        userProfileRepository: UserProfileRepository,
        selectedRole: AppUserRole
    ) {
        self.repository = repository
        self.userProfileRepository = userProfileRepository
        self.selectedRole = selectedRole
    }

    func signIn() async -> Bool {
        guard validate() else { return false }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let user = try await repository.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            guard let profile = try await userProfileRepository.loadProfile(userID: user.id) else {
                try? repository.signOut()
                errorMessage = "Профиль пользователя не найден."
                return false
            }

            guard profile.role == selectedRole else {
                try? repository.signOut()
                errorMessage = "Этот аккаунт зарегистрирован как \(profile.role.title.lowercased()). Выберите правильную роль."
                return false
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func validate() -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            errorMessage = "Введите корректный email."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Пароль должен быть не короче 6 символов."
            return false
        }

        return true
    }
}

@MainActor
final class RegisterViewModel: ObservableObject {
    private let repository: AuthRepository
    private let userProfileRepository: UserProfileRepository
    private let role: AppUserRole

    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var selectedTeacherSubject: Subject?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(
        repository: AuthRepository,
        userProfileRepository: UserProfileRepository,
        role: AppUserRole
    ) {
        self.repository = repository
        self.userProfileRepository = userProfileRepository
        self.role = role
    }

    func register() async -> Bool {
        guard validate() else { return false }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let user = try await repository.register(
                name: normalizedName,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            let profile = AppUserProfile(
                user: user,
                name: normalizedName,
                role: role,
                teacherSubject: selectedTeacherSubject
            )
            try await userProfileRepository.saveProfile(profile)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func validate() -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedName.count >= 2 else {
            errorMessage = "Введите имя."
            return false
        }

        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            errorMessage = "Введите корректный email."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Пароль должен быть не короче 6 символов."
            return false
        }

        if role == .teacher, selectedTeacherSubject == nil {
            errorMessage = "Выберите предмет."
            return false
        }

        return true
    }
}
