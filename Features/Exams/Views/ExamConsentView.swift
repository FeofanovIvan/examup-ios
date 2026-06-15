import SwiftUI

struct ExamConsentView: View {
    let context: ExamStartContext
    var requiresSafeMode = false
    let onContinue: (ExamProctoringConsent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var allowsCamera = false
    @State private var allowsMicrophone = false
    @State private var acceptedAgreement = false
    @State private var isAgreementOpen = false
    @State private var isDeclineWarningOpen = false

    private var selectedConsentCount: Int {
        [allowsCamera, allowsMicrophone, acceptedAgreement].filter { $0 }.count
    }

    private var canContinue: Bool {
        // For required SafeMode all 3 must be agreed; otherwise always allow (partial = declined)
        requiresSafeMode ? selectedConsentCount == 3 : true
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                topBar

                Image("Safe")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 172)
                    .padding(.top, -4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Честная сдача экзамена\nпод нашей защитой")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(Color(hex: "171B2A"))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(requiresSafeMode
                         ? "Для задания репетитора необходимо включить все настройки безопасного режима."
                         : "Выберите, можно ли фиксировать настройки защиты во время экзамена.")
                        .font(.system(size: 15, weight: .regular))
                        .lineSpacing(3)
                        .foregroundStyle(Color(hex: "5D657C"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    consentRow(
                        systemName: "camera",
                        title: "Разрешить включать камеру",
                        subtitle: "Только на время сдачи экзамена",
                        isOn: $allowsCamera
                    )

                    consentRow(
                        systemName: "mic",
                        title: "Разрешать включать звук",
                        subtitle: "Только на время сдачи экзамена",
                        isOn: $allowsMicrophone
                    )

                    agreementCard
                }
                .padding(.top, 4)

                Button {
                    continueTapped()
                } label: {
                    Text("Продолжить")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: canContinue
                                    ? [Color(hex: "8B67F5"), Color(hex: "6F4EEE")]
                                    : [Color(hex: "D9C9FF"), Color(hex: "C8B5FA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                .padding(.top, 2)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 22)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $isAgreementOpen) {
            agreementTemplate
        }
        .alert("Продолжить без защиты?", isPresented: $isDeclineWarningOpen) {
            Button("Отмена", role: .cancel) {}
            Button("Продолжить без защиты") {
                onContinue(.declined())
            }
        } message: {
            Text("Камера и микрофон не будут использованы. В результате будет отмечено, что вы отказались от безопасного режима.")
        }
    }

    private var topBar: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(hex: "171B2A"))
                .frame(width: 42, height: 42, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private var agreementCard: some View {
        HStack(spacing: 14) {
            consentRowContent(
                systemName: "doc.text",
                title: "Персональное согласие",
                subtitle: "Я ознакомлен и согласен с условиями",
                isOn: acceptedAgreement
            ) {
                acceptedAgreement.toggle()
            }

            Button {
                isAgreementOpen = true
            } label: {
                HStack(spacing: 5) {
                    Text("Читать")
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color(hex: "7257F4"))
                .frame(width: 72, height: 40)
                .background(Color(hex: "F4F0FF"))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E2E5EE"), lineWidth: 1)
        }
    }

    private func consentRow(
        systemName: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        consentRowContent(
            systemName: systemName,
            title: title,
            subtitle: subtitle,
            isOn: isOn.wrappedValue
        ) {
            isOn.wrappedValue.toggle()
        }
        .padding(12)
        .frame(minHeight: 76)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E2E5EE"), lineWidth: 1)
        }
    }

    private func consentRowContent(
        systemName: String,
        title: String,
        subtitle: String,
        isOn: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 46, height: 46)
                    .background(Color(hex: "EFE8FF"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "171B2A"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: "687083"))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isOn ? Color(hex: "7257F4") : Color(hex: "B8BEC9"))
            }
        }
        .buttonStyle(.plain)
    }

    private var agreementTemplate: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Шаблон персонального согласия")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: "171B2A"))

                    Text("Пользователь подтверждает, что ознакомлен с условиями проведения экзамена, понимает назначение функций контроля честности и соглашается с фиксацией выбранных настроек в экзаменационной сессии.")
                        .font(.system(size: 16))
                        .lineSpacing(4)
                        .foregroundStyle(Color(hex: "5D657C"))

                    Text("На данном этапе приложение не включает камеру, микрофон и запись экрана. Согласие используется как архитектурная заготовка для будущего отчета по экзамену.")
                        .font(.system(size: 16))
                        .lineSpacing(4)
                        .foregroundStyle(Color(hex: "5D657C"))
                }
                .padding(24)
            }
            .navigationTitle("Соглашение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        isAgreementOpen = false
                    }
                }
            }
        }
    }

    private func continueTapped() {
        guard canContinue else { return }
        if selectedConsentCount == 3 {
            onContinue(.accepted())
        } else if requiresSafeMode {
            // Should not reach here — button is disabled
        } else {
            // Partial or no consent — treat as declined, show warning
            isDeclineWarningOpen = true
        }
    }
}
