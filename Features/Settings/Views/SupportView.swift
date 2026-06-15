import SwiftUI

struct SupportView: View {
    let onBack: () -> Void

    private let faqItems: [(String, String)] = [
        ("Как работает SafeMode?",
         "SafeMode фиксирует присутствие ученика через камеру и микрофон во время экзамена. Все данные хранятся локально и передаются только репетитору."),
        ("Можно ли пройти экзамен без интернета?",
         "Да. Базы заданий загружаются заранее. Результаты синхронизируются автоматически при появлении сети."),
        ("Как изменить предметы?",
         "Перейдите в Настройки → Предметы и скачайте нужную базу заданий."),
        ("Почему не отображается чертёж?",
         "Некоторые задания содержат графику, которая загружается вместе с базой предмета. Убедитесь, что база скачана полностью."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                contactSection
                faqSection
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
                Text("Помощь и поддержка")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("Ответы на частые вопросы")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Связаться с нами")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
                .padding(.top, 4)

            VStack(spacing: 0) {
                contactRow(
                    icon: "envelope.fill", tint: "7257F4",
                    title: "Написать на email",
                    subtitle: "support@examup.ru",
                    action: { openEmail() }
                )
                Divider().padding(.leading, 52)
                contactRow(
                    icon: "paperplane.fill", tint: "2F80ED",
                    title: "Telegram",
                    subtitle: "@examup_support",
                    action: { openTelegram() }
                )
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
            }
        }
    }

    private func contactRow(icon: String, tint: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "687083"))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }
            .padding(.horizontal, 14)
            .frame(height: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Частые вопросы")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
                .padding(.top, 4)

            VStack(spacing: 10) {
                ForEach(faqItems, id: \.0) { question, answer in
                    faqCard(question: question, answer: answer)
                }
            }
        }
    }

    private func faqCard(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))
            Text(answer)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "687083"))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private func openEmail() {
        if let url = URL(string: "mailto:support@examup.ru") {
            UIApplication.shared.open(url)
        }
    }

    private func openTelegram() {
        if let url = URL(string: "https://t.me/examup_support") {
            UIApplication.shared.open(url)
        }
    }
}
