import Foundation

struct SettingsSection: Identifiable, Equatable {
    let id: String
    let title: String
    let rows: [SettingsRow]
}

struct SettingsRow: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let tintHex: String
    let trailingTitle: String?
    let isDestructive: Bool
}

struct SettingsDashboard: Equatable {
    let displayName: String
    let email: String
    let sections: [SettingsSection]

    static let placeholder = SettingsDashboard(
        displayName: "Пользователь",
        email: "email не указан",
        sections: []
    )
}
