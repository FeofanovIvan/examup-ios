import Foundation
import FirebaseAuth

protocol SettingsRepository {
    func loadDashboard() async throws -> SettingsDashboard
}

struct DefaultSettingsRepository: SettingsRepository {
    func loadDashboard() async throws -> SettingsDashboard {
        let user = Auth.auth().currentUser
        let email = user?.email ?? "email не указан"
        let name = user?.displayName?.isEmpty == false ? user?.displayName : email.components(separatedBy: "@").first

        return SettingsDashboard(
            displayName: name ?? "Пользователь",
            email: email,
            sections: [
                SettingsSection(
                    id: "account",
                    title: "Аккаунт",
                    rows: [
                        SettingsRow(id: "profile", title: "Профиль", systemImage: "person", tintHex: "7257F4", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "security", title: "Безопасность", systemImage: "shield", tintHex: "2F80ED", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "notifications", title: "Уведомления", systemImage: "bell", tintHex: "22A95A", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "theme", title: "Тема приложения", systemImage: "paintpalette", tintHex: "FB8A2E", trailingTitle: "Светлая", isDestructive: false)
                    ]
                ),
                SettingsSection(
                    id: "learning",
                    title: "Обучение",
                    rows: [
                        SettingsRow(id: "subjects", title: "Предметы", systemImage: "book", tintHex: "7257F4", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "exam-settings", title: "Настройки экзаменов", systemImage: "slider.horizontal.3", tintHex: "2F80ED", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "deadlines", title: "Календарь и дедлайны", systemImage: "calendar", tintHex: "22A95A", trailingTitle: nil, isDestructive: false)
                    ]
                ),
                SettingsSection(
                    id: "app",
                    title: "Приложение",
                    rows: [
                        SettingsRow(id: "support", title: "Помощь и поддержка", systemImage: "questionmark.circle", tintHex: "7257F4", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "about", title: "О приложении", systemImage: "info.circle", tintHex: "2F80ED", trailingTitle: "1.2.0", isDestructive: false),
                        SettingsRow(id: "rate", title: "Оценить приложение", systemImage: "star", tintHex: "FB8A2E", trailingTitle: nil, isDestructive: false),
                        SettingsRow(id: "signout", title: "Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right", tintHex: "FF3B30", trailingTitle: nil, isDestructive: true)
                    ]
                )
            ]
        )
    }
}
