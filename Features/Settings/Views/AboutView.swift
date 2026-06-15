import SwiftUI

struct AboutView: View {
    let onBack: () -> Void

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                appCard
                infoSection
                legalSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("О приложении")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("ExamUp — подготовка к экзаменам")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
    }

    private var appCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "8B67F5"), Color(hex: "6F4EEE")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("ExamUp")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("Версия \(appVersion) (сборка \(buildNumber))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Информация")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
                .padding(.top, 4)

            VStack(spacing: 0) {
                infoRow(icon: "number", tint: "7257F4", label: "Версия", value: appVersion)
                Divider().padding(.leading, 52)
                infoRow(icon: "hammer.fill", tint: "2F80ED", label: "Сборка", value: buildNumber)
                Divider().padding(.leading, 52)
                infoRow(icon: "iphone", tint: "22A95A", label: "Платформа", value: "iOS 17+")
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
            }
        }
    }

    private func infoRow(icon: String, tint: String, label: String, value: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: tint))
                .frame(width: 28)

            Text(label)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "687083"))
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Юридическая информация")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
                .padding(.top, 4)

            VStack(spacing: 0) {
                legalRow(title: "Политика конфиденциальности", url: "https://examup.ru/privacy")
                Divider().padding(.leading, 52)
                legalRow(title: "Условия использования", url: "https://examup.ru/terms")
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
            }

            Text("© 2024–2025 ExamUp. Все права защищены.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8C94A3"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }

    private func legalRow(title: String, url: String) -> some View {
        Button {
            if let link = URL(string: url) { UIApplication.shared.open(link) }
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "8C94A3"))
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
