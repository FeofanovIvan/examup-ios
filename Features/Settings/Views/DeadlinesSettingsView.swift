import SwiftUI

struct DeadlinesSettingsView: View {
    @StateObject var viewModel: DeadlinesSettingsViewModel
    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                settingsGroup(title: "Напоминания") {
                    toggleRow(
                        icon: "bell.fill", tint: "22A95A",
                        title: "Напоминания о дедлайнах",
                        subtitle: "Уведомление за несколько дней до срока",
                        isOn: $viewModel.remindersEnabled
                    )

                    if viewModel.remindersEnabled {
                        Divider().padding(.leading, 52)
                        pickerRow(
                            icon: "calendar.badge.clock", tint: "7257F4",
                            title: "За сколько дней",
                            selection: $viewModel.remindDaysBefore,
                            options: viewModel.daysOptions.map { n -> (String, Int) in
                                let word: String
                                switch n {
                                case 1: word = "день"
                                case 2, 3, 4: word = "дня"
                                default: word = "дней"
                                }
                                return ("\(n) \(word)", n)
                            }
                        )
                    }
                }

                settingsGroup(title: "Ежедневное напоминание") {
                    toggleRow(
                        icon: "sunrise.fill", tint: "FB8A2E",
                        title: "Утреннее напоминание",
                        subtitle: "Ежедневно напоминать о текущих задачах",
                        isOn: $viewModel.morningReminder
                    )

                    if viewModel.morningReminder {
                        Divider().padding(.leading, 52)
                        pickerRow(
                            icon: "clock.fill", tint: "2F80ED",
                            title: "Время напоминания",
                            selection: $viewModel.reminderHour,
                            options: (6...22).map { h in (String(format: "%02d:00", h), h) }
                        )
                    }
                }

                Text("Уведомления отправляются только при включённых системных разрешениях.")
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
                Text("Календарь и дедлайны")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("Управляйте напоминаниями о сроках")
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

    private func toggleRow(icon: String, tint: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
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

    private func pickerRow(icon: String, tint: String, title: String, selection: Binding<Int>, options: [(String, Int)]) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: tint))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            Spacer()

            Picker("", selection: selection) {
                ForEach(options, id: \.1) { label, value in
                    Text(label).tag(value)
                }
            }
            .labelsHidden()
            .tint(Color(hex: "7257F4"))
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 56)
    }
}
