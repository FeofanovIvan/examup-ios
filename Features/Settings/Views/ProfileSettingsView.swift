import SwiftUI

struct ProfileSettingsView: View {
    @StateObject var viewModel: ProfileSettingsViewModel
    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                avatarSection
                formSection
                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { onBack() }
        }
    }

    // MARK: - Subviews

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
                Text("Профиль")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text("Редактируйте данные аккаунта")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
    }

    private var avatarSection: some View {
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                Text(viewModel.displayName.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 88, height: 88)
                    .background(Color(hex: "F1EBFF"))
                    .clipShape(Circle())

                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .background(.white)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var formSection: some View {
        VStack(spacing: 0) {
            settingsField(
                icon: "person",
                tint: "7257F4",
                label: "Имя",
                placeholder: "Введите имя",
                text: $viewModel.displayName
            )

            Divider().padding(.leading, 52)

            HStack(spacing: 13) {
                Image(systemName: "envelope")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "2F80ED"))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Email")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "8C94A3"))
                    Text(viewModel.email.isEmpty ? "—" : viewModel.email)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "6B7280"))
                }

                Spacer()

                if viewModel.isEmailVerified {
                    Label("Подтверждён", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "22A95A"))
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(Color(hex: "22A95A").opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private func settingsField(
        icon: String,
        tint: String,
        label: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: tint))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "8C94A3"))
                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
    }

    private var saveButton: some View {
        VStack(spacing: 10) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF3B30"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            Button {
                Task { await viewModel.save() }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Сохранить")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.canSave
                        ? LinearGradient(colors: [Color(hex: "8B67F5"), Color(hex: "6F4EEE")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color(hex: "D9C9FF"), Color(hex: "C8B5FA")], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSave)
        }
    }
}
