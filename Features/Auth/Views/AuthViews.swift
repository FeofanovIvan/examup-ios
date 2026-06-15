import SwiftUI

struct WelcomeView: View {
    @StateObject var viewModel: WelcomeViewModel
    let selectedRole: AppUserRole
    let onContinue: () -> Void
    let onChangeRole: () -> Void

    var body: some View {
        LoginView(
            viewModel: LoginViewModel(
                repository: viewModel.repository,
                userProfileRepository: viewModel.userProfileRepository,
                selectedRole: selectedRole
            ),
            registerViewModel: RegisterViewModel(
                repository: viewModel.repository,
                userProfileRepository: viewModel.userProfileRepository,
                role: selectedRole
            ),
            selectedRole: selectedRole,
            onAuthenticated: onContinue,
            onChangeRole: onChangeRole
        )
    }
}

struct RoleSelectionView: View {
    let onRoleSelected: (AppUserRole) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Кто вы?")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("Это настроит структуру приложения под ваши задачи.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "4C515C"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            VStack(spacing: 11) {
                RoleSelectionCard(
                    title: AppUserRole.student.title,
                    subtitle: "Подготовка к экзаменам, задания, календарь и репетиторы",
                    systemImage: "graduationcap.fill",
                    tint: Color(hex: "7257F4")
                ) {
                    onRoleSelected(.student)
                }

                RoleSelectionCard(
                    title: AppUserRole.teacher.title,
                    subtitle: "Ученики, задания, экзамены и результаты в отдельном кабинете",
                    systemImage: "person.crop.rectangle.stack.fill",
                    tint: Color(hex: "3F86E8")
                ) {
                    onRoleSelected(.teacher)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(Color(hex: "FBFCFF"))
        .navigationTitle("Первый вход")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RoleSelectionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: "4C515C"))
                        .lineLimit(3)
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "87909D"))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E3E7EE"), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    @StateObject var registerViewModel: RegisterViewModel
    let selectedRole: AppUserRole
    let onAuthenticated: () -> Void
    let onChangeRole: () -> Void

    var body: some View {
        AuthScreenScaffold {
            VStack(spacing: 14) {
                AuthHero(
                    title: "Добро пожаловать!",
                    subtitle: "Войдите в свой аккаунт,\nчтобы продолжить подготовку"
                )

                VStack(spacing: 10) {
                    AuthTextField(
                        title: "Электронная почта",
                        systemImage: "person.fill",
                        text: $viewModel.email,
                        keyboardType: .emailAddress
                    )

                    AuthSecureField(title: "Пароль", text: $viewModel.password)

                    Button("Забыли пароль?") {}
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "7B5CF6"))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    AuthErrorText(message: viewModel.errorMessage)

                    AuthPrimaryButton(title: "Войти", isLoading: viewModel.isLoading) {
                        Task {
                            if await viewModel.signIn() {
                                onAuthenticated()
                            }
                        }
                    }
                }

                AuthDivider()

                VStack(spacing: 9) {
                    AuthSocialButton(title: "Войти через VK", badgeText: "VK", badgeColor: Color(hex: "2787F5"))
                    AuthSocialButton(title: "Войти через Google", badgeText: "G", badgeColor: .white)
                }

                HStack(spacing: 6) {
                    Text("Нет аккаунта?")
                        .foregroundStyle(Color(hex: "6E7486"))

                    NavigationLink("Зарегистрироваться") {
                        RegisterView(viewModel: registerViewModel, selectedRole: selectedRole, onAuthenticated: onAuthenticated)
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "7B5CF6"))
                }
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

                Button("Изменить роль: \(selectedRole.title)", action: onChangeRole)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "8A91A3"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct RegisterView: View {
    @StateObject var viewModel: RegisterViewModel
    let selectedRole: AppUserRole
    let onAuthenticated: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AuthScreenScaffold {
            VStack(spacing: 14) {
                AuthHero(
                    title: "Создайте аккаунт",
                    subtitle: "Мы подготовим профиль для роли\n\(selectedRole.title.lowercased())"
                )

                VStack(spacing: 10) {
                    AuthTextField(
                        title: "Имя",
                        systemImage: "person.fill",
                        text: $viewModel.name,
                        keyboardType: .default
                    )

                    AuthTextField(
                        title: "Электронная почта",
                        systemImage: "envelope.fill",
                        text: $viewModel.email,
                        keyboardType: .emailAddress
                    )

                    AuthSecureField(title: "Пароль", text: $viewModel.password)

                    if selectedRole == .teacher {
                        AuthSubjectPicker(selectedSubject: $viewModel.selectedTeacherSubject)
                    }

                    AuthErrorText(message: viewModel.errorMessage)

                    AuthPrimaryButton(title: "Зарегистрироваться", isLoading: viewModel.isLoading) {
                        Task {
                            if await viewModel.register() {
                                onAuthenticated()
                            }
                        }
                    }
                }

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Text("Уже есть аккаунт?")
                            .foregroundStyle(Color(hex: "6E7486"))

                        Text("Войти")
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "7B5CF6"))
                    }
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AuthSubjectPicker: View {
    @Binding var selectedSubject: Subject?

    var body: some View {
        Menu {
            ForEach(Subject.placeholders) { subject in
                Button(subject.title) {
                    selectedSubject = subject
                }
            }
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(hex: "7B5CF6"))
                    .frame(width: 23)

                Text(selectedSubject?.title ?? "Выберите предмет")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selectedSubject == nil ? Color(hex: "A1A8B8") : Color(hex: "18213A"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "777F95"))
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(.white.opacity(0.94))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "E2E6F0"), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "9CA8C6").opacity(0.16), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

struct EmailVerificationView: View {
    @StateObject var viewModel: AuthPlaceholderViewModel

    var body: some View {
        ScreenContainer(title: viewModel.title) {
            PlaceholderBlock(title: "Email Verification Placeholder")
        }
    }
}

struct InitialSetupView: View {
    @StateObject var viewModel: AuthPlaceholderViewModel

    var body: some View {
        ScreenContainer(title: viewModel.title) {
            PlaceholderBlock(title: "Initial Setup Placeholder")
        }
    }
}

private struct AuthFormHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "626A78"))
        }
        .padding(.bottom, 8)
    }
}

private struct AuthScreenScaffold<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "F7F9FF"),
                    Color(hex: "EEF3FF"),
                    Color(hex: "F8FAFF")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct AuthHero: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image("auth")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 270)
                .frame(height: 225)
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "18213A"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "6F768A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
    }
}

private struct AuthTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(hex: "7B5CF6"))
                .frame(width: 23)

            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "18213A"))
                .tint(Color(hex: "7B5CF6"))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(.white.opacity(0.94))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E2E6F0"), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color(hex: "9CA8C6").opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    @State private var isPasswordVisible = false

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "lock.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(hex: "7B5CF6"))
                .frame(width: 23)

            Group {
                if isPasswordVisible {
                    TextField(title, text: $text)
                } else {
                    SecureField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(hex: "18213A"))
            .tint(Color(hex: "7B5CF6"))

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(hex: "777F95"))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(.white.opacity(0.94))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E2E6F0"), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color(hex: "9CA8C6").opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

private struct AuthDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(hex: "DDE3F0"))
                .frame(height: 1)

            Text("или")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "6F768A"))

            Rectangle()
                .fill(Color(hex: "DDE3F0"))
                .frame(height: 1)
        }
        .padding(.vertical, 2)
    }
}

private struct AuthSocialButton: View {
    let title: String
    let badgeText: String
    let badgeColor: Color

    var body: some View {
        Button {} label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 28, height: 28)
                        .shadow(color: Color(hex: "9CA8C6").opacity(0.18), radius: 8, x: 0, y: 4)

                    Text(badgeText)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(badgeText == "G" ? Color(hex: "4285F4") : .white)
                }
                .frame(width: 40)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "18213A"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(height: 52)
            .background(.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "9CA8C6").opacity(0.14), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(true)
    }
}

private struct AuthErrorText: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(isLoading ? "Подождите..." : title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    colors: [Color(hex: "8C68F7"), Color(hex: "6C4BEA")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: "7257F4").opacity(0.28), radius: 18, x: 0, y: 12)
        }
        .disabled(isLoading)
    }
}
