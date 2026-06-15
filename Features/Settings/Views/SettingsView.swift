import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    let onNavigate: (SettingsRoute) -> Void
    let onSignOut: () -> Void

    @State private var isPremiumPresented = false
    @State private var isThemePickerPresented = false
    @AppStorage("app.colorScheme") private var colorSchemeRaw = "system"

    private var themeLabel: String {
        switch colorSchemeRaw {
        case "light": return "Светлая"
        case "dark":  return "Тёмная"
        default:      return "Системная"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                profileCard
                premiumCard

                ForEach(viewModel.dashboard.sections) { section in
                    settingsSection(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .fullScreenCover(isPresented: $isPremiumPresented) {
            PremiumSubscriptionView()
        }
        .confirmationDialog("Тема приложения", isPresented: $isThemePickerPresented, titleVisibility: .visible) {
            Button("Светлая")   { colorSchemeRaw = "light" }
            Button("Тёмная")    { colorSchemeRaw = "dark" }
            Button("Системная") { colorSchemeRaw = "system" }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Настройки")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))
            Text("Управляйте профилем и приложением")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "4C515C"))
        }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        Button { onNavigate(.profile) } label: {
            HStack(spacing: 14) {
                Text(viewModel.dashboard.displayName.prefix(1).uppercased())
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 64, height: 64)
                    .background(Color(hex: "F1EBFF"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.dashboard.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(viewModel.dashboard.email)
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

    // MARK: - Premium card

    private var premiumCard: some View {
        Button { isPremiumPresented = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color(hex: "7257F4"))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Премиум доступ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                    Text("Откройте все возможности приложения")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "687083"))
                        .lineLimit(2)
                }

                Spacer()

                Text("Premium")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Color(hex: "7257F4"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
            }
            .padding(14)
            .background(Color(hex: "F4F0FF"))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sections

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

    private func settingsRow(_ row: SettingsRow) -> some View {
        Button { handleRowTap(row) } label: {
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

                // Dynamic trailing for theme
                let trailing = row.id == "theme" ? themeLabel : row.trailingTitle
                if let label = trailing {
                    Text(label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Color(hex: "F4F0FF"))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handleRowTap(_ row: SettingsRow) {
        switch row.id {
        case "signout":
            onSignOut()
        case "theme":
            isThemePickerPresented = true
        case "rate":
            rateApp()
        default:
            if let route = SettingsRoute(rowID: row.id) {
                onNavigate(route)
            }
        }
    }

    private func rateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id0000000000?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}
