import SwiftUI

struct TeacherSettingsView: View {
    let summary: TeacherHomeSummary
    let onSignOut: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isThemePickerPresented = false
    @AppStorage("app.colorScheme") private var colorSchemeRaw = "system"

    private var themeLabel: String {
        switch colorSchemeRaw {
        case "light": return "Светлая"
        case "dark": return "Тёмная"
        default: return "Системная"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                profileCard

                ForEach(sections) { section in
                    settingsSection(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Тема приложения", isPresented: $isThemePickerPresented, titleVisibility: .visible) {
            Button("Светлая") { colorSchemeRaw = "light" }
            Button("Тёмная") { colorSchemeRaw = "dark" }
            Button("Системная") { colorSchemeRaw = "system" }
            Button("Отмена", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Настройки")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("Управляйте профилем и приложением")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "4C515C"))
            }
        }
    }

    private var profileCard: some View {
        NavigationLink(value: TeacherSettingsRoute.profile) {
            HStack(spacing: 14) {
                Text(summary.displayName.prefix(1).uppercased())
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 64, height: 64)
                    .background(Color(hex: "F1EBFF"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(summary.subjectTitle) · ID \(summary.publicId)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "687083"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.045), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func settingsSection(_ section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
                .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    settingsRow(row)
                    if index < section.rows.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func settingsRow(_ row: SettingsRow) -> some View {
        if let route = route(for: row.id) {
            NavigationLink(value: route) {
                rowLabel(row)
            }
            .buttonStyle(.plain)
        } else {
            Button { handleAction(row.id) } label: {
                rowLabel(row)
            }
            .buttonStyle(.plain)
        }
    }

    private func rowLabel(_ row: SettingsRow) -> some View {
        HStack(spacing: 13) {
            Image(systemName: row.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: row.tintHex))
                .frame(width: 28)

            Text(row.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(row.isDestructive ? Color(hex: "FF3B30") : Color(hex: "20242D"))
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer()

            let trailing = row.id == "theme" ? themeLabel : row.trailingTitle
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Color(hex: "F4F0FF"))
                    .clipShape(Capsule())
            }

            if row.id != "subject" {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    private func route(for id: String) -> TeacherSettingsRoute? {
        switch id {
        case "profile": return .profile
        case "security": return .security
        case "notifications": return .notifications
        case "exam-settings": return .examSettings
        case "deadlines": return .deadlines
        case "support": return .support
        case "about": return .about
        default: return nil
        }
    }

    private func handleAction(_ id: String) {
        switch id {
        case "theme":
            isThemePickerPresented = true
        case "rate":
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id0000000000?action=write-review") {
                UIApplication.shared.open(url)
            }
        case "signout":
            onSignOut()
        default:
            break
        }
    }

    private var sections: [SettingsSection] {
        [
            SettingsSection(
                id: "teacher-account",
                title: "Аккаунт",
                rows: [
                    SettingsRow(id: "profile", title: "Профиль", systemImage: "person", tintHex: "7257F4", trailingTitle: nil, isDestructive: false),
                    SettingsRow(id: "security", title: "Безопасность", systemImage: "shield", tintHex: "2F80ED", trailingTitle: nil, isDestructive: false),
                    SettingsRow(id: "notifications", title: "Уведомления", systemImage: "bell", tintHex: "22A95A", trailingTitle: nil, isDestructive: false),
                    SettingsRow(id: "theme", title: "Тема приложения", systemImage: "paintpalette", tintHex: "FB8A2E", trailingTitle: nil, isDestructive: false)
                ]
            ),
            SettingsSection(
                id: "teacher-work",
                title: "Обучение",
                rows: [
                    SettingsRow(id: "subject", title: "Предмет", systemImage: "book", tintHex: "7257F4", trailingTitle: summary.subjectTitle, isDestructive: false),
                    SettingsRow(id: "exam-settings", title: "Настройки экзаменов", systemImage: "slider.horizontal.3", tintHex: "2F80ED", trailingTitle: nil, isDestructive: false),
                    SettingsRow(id: "deadlines", title: "Календарь и дедлайны", systemImage: "calendar", tintHex: "22A95A", trailingTitle: nil, isDestructive: false)
                ]
            ),
            SettingsSection(
                id: "teacher-app",
                title: "Приложение",
                rows: [
                    SettingsRow(id: "support", title: "Помощь и поддержка", systemImage: "questionmark.circle", tintHex: "7257F4", trailingTitle: nil, isDestructive: false),
                    SettingsRow(id: "about", title: "О приложении", systemImage: "info.circle", tintHex: "2F80ED", trailingTitle: "1.2.0", isDestructive: false),
                    SettingsRow(id: "rate", title: "Оценить приложение", systemImage: "star", tintHex: "FB8A2E", trailingTitle: nil, isDestructive: false),
                    SettingsRow(id: "signout", title: "Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right", tintHex: "FF3B30", trailingTitle: nil, isDestructive: true)
                ]
            )
        ]
    }
}
