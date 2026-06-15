import SwiftUI

struct NotificationsSettingsView: View {
    @StateObject var viewModel: NotificationsSettingsViewModel
    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                settingsGroup(title: "Экзамены и учёба") {
                    toggleRow(
                        icon: "doc.text.fill", tint: "7257F4",
                        title: "Напоминания об экзаменах",
                        subtitle: "За день до запланированного экзамена",
                        isOn: $viewModel.notifyExams
                    )
                    Divider().padding(.leading, 52)
                    toggleRow(
                        icon: "calendar.badge.clock", tint: "22A95A",
                        title: "Дедлайны",
                        subtitle: "Уведомление при приближении срока",
                        isOn: $viewModel.notifyDeadlines
                    )
                    Divider().padding(.leading, 52)
                    toggleRow(
                        icon: "bell.badge.fill", tint: "FB8A2E",
                        title: "Напоминания о занятиях",
                        subtitle: "Ежедневное напоминание заниматься",
                        isOn: $viewModel.notifyReminders
                    )
                }

                settingsGroup(title: "Репетитор") {
                    toggleRow(
                        icon: "person.2.fill", tint: "2F80ED",
                        title: "Сообщения от репетитора",
                        subtitle: "Новые задания и комментарии",
                        isOn: $viewModel.notifyTutor
                    )
                }

                Text("Системные разрешения для уведомлений управляются в Настройках iPhone.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "8C94A3"))
                    .padding(.horizontal, 4)
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
                Text("Уведомления")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("Настройте, какие уведомления получать")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
                .padding(.top, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
            }
        }
    }

    private func toggleRow(
        icon: String,
        tint: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: tint))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "7257F4"))
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
        .contentShape(Rectangle())
    }
}
