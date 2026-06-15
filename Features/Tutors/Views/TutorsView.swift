import SwiftUI

struct TutorsView: View {
    @StateObject var viewModel: TutorsViewModel
    @ObservedObject var notificationsViewModel: NotificationsViewModel
    @State private var isAddTutorExpanded = false
    @State private var isInviteTutorExpanded = false
    @State private var selectedAddTutorPage = 0
    var onNotificationsTap: () -> Void = {}
    var onAssignmentSelected: (ExamConstructorStartContext) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                addTutorCard
                tutorsSection
                assignmentsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Репетиторы")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Управляйте репетиторами и заданиями")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "4C515C"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }

            Spacer()

            ZStack(alignment: .topTrailing) {
                Button(action: onNotificationsTap) {
                    Image(systemName: "bell")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Color(hex: "20242D"))
                        .frame(width: 48, height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 7)
                }
                .buttonStyle(.plain)

                if pendingNotifications > 0 {
                    Text("\(pendingNotifications)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color(hex: "7257F4"))
                        .clipShape(Circle())
                        .offset(x: 8, y: -7)
                }
            }
        }
    }

    private var addTutorCard: some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedAddTutorPage) {
                tutorActionBlock(
                    title: "Добавить репетитора",
                    subtitle: "Найдите преподавателя по его ID",
                    systemImage: "person.badge.plus",
                    isExpanded: $isAddTutorExpanded,
                    fieldTitle: "ID репетитора",
                    placeholder: "Например 974048",
                    text: $viewModel.tutorID,
                    keyboardType: .numberPad,
                    buttonTitle: viewModel.isLoading ? "Добавляем..." : "Добавить репетитора"
                ) {
                    Task { await viewModel.addTutor() }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .tag(0)

                tutorActionBlock(
                    title: "Пригласить репетитора",
                    subtitle: "Отправьте приглашение по почте",
                    systemImage: "envelope.badge.person.crop",
                    isExpanded: $isInviteTutorExpanded,
                    fieldTitle: "Email репетитора",
                    placeholder: "teacher@example.com",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    buttonTitle: viewModel.isLoading ? "Отправляем..." : "Пригласить"
                ) {
                    Task { await viewModel.inviteTutor() }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: selectedActionIsExpanded ? 252 : 76, alignment: .top)

            HStack(spacing: 7) {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(index == selectedAddTutorPage ? Color(hex: "7257F4") : Color(hex: "DDE1EA"))
                        .frame(
                            width: index == selectedAddTutorPage ? 8 : 7,
                            height: index == selectedAddTutorPage ? 8 : 7
                        )
                }
            }
            .frame(maxWidth: .infinity)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF4D55"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let message = viewModel.successMessage {
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "29B765"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var selectedActionIsExpanded: Bool {
        selectedAddTutorPage == 0 ? isAddTutorExpanded : isInviteTutorExpanded
    }

    private func tutorActionBlock(
        title: String,
        subtitle: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        fieldTitle: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isExpanded.wrappedValue.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                        .frame(width: 42, height: 42)
                        .background(Color(hex: "F4F0FF"))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "20242D"))

                        Text(subtitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "7B8194"))
                    }

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                tutorInput(title: fieldTitle, placeholder: placeholder, text: text, keyboardType: keyboardType)

                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "7257F4"))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
        }
        .padding(14)
        .background(Color(hex: "FCFAFF"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E5DAFF"), lineWidth: 1)
        }
    }

    private func tutorInput(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "7B8194"))

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "20242D"))
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(hex: "E1E4ED"), lineWidth: 1)
                }
        }
    }

    private var tutorsSection: some View {
        VStack(spacing: 10) {
            if viewModel.tutors.isEmpty {
                emptyTutorCard
            } else {
                ForEach(viewModel.tutors) { tutor in
                    TutorConnectionCard(tutor: tutor) {
                        Task {
                            await viewModel.removeTutor(tutor)
                        }
                    }
                }
            }
        }
    }

    private var emptyTutorCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "7257F4"))
                .frame(width: 62, height: 62)
                .background(Color(hex: "F4F0FF"))
                .clipShape(Circle())

            Text("Репетиторы пока не добавлены")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            Text("Добавьте существующего репетитора по ID или пригласите нового по email.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "7B8194"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 7)
    }

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Предстоящие события")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))
                .padding(.top, 2)

            if viewModel.assignments.isEmpty {
                Text("Задания появятся после подключения репетитора.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "7B8194"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(viewModel.assignments) { assignment in
                    Button {
                        Task {
                            if let context = await viewModel.prepareAssignment(assignment) {
                                onAssignmentSelected(context)
                            }
                        }
                    } label: {
                        TutorAssignmentRow(assignment: assignment)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .disabled(assignment.isSubmitted)
                }
            }

            Button(action: {}) {
                HStack {
                        Text("Посмотреть все задания")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Color(hex: "7257F4"))
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pendingNotifications: Int {
        notificationsViewModel.unreadCount
    }
}

private struct TutorConnectionCard: View {
    let tutor: TutorConnection
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 56, height: 56)
                    .background(Color(hex: "F1EBFF"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(tutor.name.isEmpty ? "Репетитор" : tutor.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(tutor.email.isEmpty ? "ID \(tutor.tutorID)" : "\(tutor.email) · ID \(tutor.tutorID)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "7B8194"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(tutor.subject.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                        .padding(.horizontal, 8)
                        .frame(height: 23)
                        .background(Color(hex: "F4F0FF"))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 6)

                HStack(spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: "20242D"))
                            .frame(width: 40, height: 40)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                            }

                        if tutor.pendingNotifications > 0 {
                            Text("\(tutor.pendingNotifications)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(Color(hex: "7257F4"))
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }

                    Menu {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Удалить репетитора", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "7B8194"))
                            .frame(width: 34, height: 40)
                    }
                }
            }

            let percent = tutor.totalAssignments == 0 ? 0 : Int(Double(tutor.completedAssignments) / Double(tutor.totalAssignments) * 100)
            HStack(spacing: 8) {
                tutorMetric(title: "Всего", value: "\(tutor.totalAssignments)", systemImage: "clipboard")
                tutorMetric(title: "Выполнено", value: "\(tutor.completedAssignments) (\(percent)%)", systemImage: "checkmark.circle")
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.045), radius: 12, x: 0, y: 6)
    }

    private func tutorMetric(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "7257F4"))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "7B8194"))
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(Color(hex: "F8F6FF"))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct TutorAssignmentRow: View {
    let assignment: TutorAssignment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(subjectSymbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(subjectTint)
                .frame(width: 50, height: 50)
                .background(subjectTint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(assignment.subject.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                Text(assignment.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "7B8194"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 8) {
                    Label(assignment.isSubmitted ? "Сдано" : assignment.dueTitle, systemImage: assignment.isSubmitted ? "checkmark.circle.fill" : "calendar")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(statusTint)
                        .lineLimit(1)

                    Text(assignment.isSubmitted ? "Первая попытка завершена" : assignment.remainingTitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(statusTint)
                        .padding(.horizontal, 8)
                        .frame(height: 25)
                        .background(statusTint.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(assignment.tutorEmail)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "7B8194"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(assignment.isSubmitted ? Color(hex: "F1FBF5") : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(assignment.isSubmitted ? Color(hex: "BFE8CF") : Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private var subjectSymbol: String {
        switch assignment.subject.id {
        case "math": return "√x"
        case "russian": return "Ру"
        case "history": return "И"
        default: return "Ex"
        }
    }

    private var subjectTint: Color {
        if assignment.isSubmitted {
            return Color(hex: "22A95A")
        }
        switch assignment.subject.id {
        case "math": return Color(hex: "7257F4")
        case "russian": return Color(hex: "4D8DF7")
        case "history": return Color(hex: "36B96D")
        default: return Color(hex: "FB8A2E")
        }
    }

    private var statusTint: Color {
        assignment.isSubmitted ? Color(hex: "22A95A") : Color(hex: "7257F4")
    }
}
