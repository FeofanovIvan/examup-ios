import SwiftUI

struct TeacherStudentsView: View {
    @StateObject private var viewModel: TeacherStudentsViewModel
    private let repository: TeacherStudentsRepository
    private let assignmentHistoryRepository: TeacherAssignmentHistoryRepository
    @State private var studentToDelete: TeacherLocalStudent?

    init(
        repository: TeacherStudentsRepository,
        assignmentHistoryRepository: TeacherAssignmentHistoryRepository
    ) {
        self.repository = repository
        self.assignmentHistoryRepository = assignmentHistoryRepository
        _viewModel = StateObject(wrappedValue: TeacherStudentsViewModel(repository: repository))
    }

    var body: some View {
        TeacherWorkspaceScreen(title: "Ученики", subtitle: "\(viewModel.students.count) в локальном списке") {
            VStack(spacing: 12) {
                HStack {
                    Text(viewModel.selectedClass.isEmpty ? "Все ученики" : "Класс: \(viewModel.selectedClass)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "17213A"))

                    Spacer()

                    Menu {
                        Button("Все классы") { viewModel.selectedClass = "" }
                        ForEach(viewModel.classes, id: \.self) { className in
                            Button(className) { viewModel.selectedClass = className }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(hex: "7257F4"))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "F1EBFF"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                if viewModel.isLoading {
                    ProgressView().padding(.vertical, 30)
                } else if viewModel.filteredStudents.isEmpty {
                    TeacherInfoCard(
                        systemImage: "person.badge.plus",
                        tintHex: "7257F4",
                        title: "Список пока пуст",
                        subtitle: "Добавьте ученика по ID. Данные сохранятся только на этом устройстве."
                    )
                } else {
                    ForEach(viewModel.filteredStudents) { student in
                        studentCard(student)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.load() } }
        .alert("Удалить ученика?", isPresented: Binding(
            get: { studentToDelete != nil },
            set: { if !$0 { studentToDelete = nil } }
        )) {
            Button("Удалить", role: .destructive) {
                guard let student = studentToDelete else { return }
                Task { await viewModel.delete(student) }
                studentToDelete = nil
            }
            Button("Отмена", role: .cancel) { studentToDelete = nil }
        }
    }

    private func studentCard(_ student: TeacherLocalStudent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: "F1EBFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "17213A"))
                    Text("ID \(student.publicID)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "687083"))
                    if !student.className.isEmpty {
                        Text("Класс: \(student.className)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "687083"))
                    }
                }
                Spacer(minLength: 0)
            }

            if !student.note.isEmpty {
                Text(student.note)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "687083"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Button { studentToDelete = student } label: {
                    studentAction("trash", color: "FF3B30")
                }

                NavigationLink {
                    TeacherStudentEditorView(student: student, repository: repository)
                } label: {
                    studentAction("pencil", color: "7257F4")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeacherAssignmentHistoryView(
                        viewModel: TeacherAssignmentHistoryViewModel(
                            repository: assignmentHistoryRepository,
                            studentID: student.id
                        ),
                        title: "История ученика",
                        subtitle: "\(student.displayName) · ID \(student.publicID)"
                    )
                } label: {
                    Label("История", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "17213A"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(hex: "F7F8FC"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private func studentAction(_ image: String, color: String) -> some View {
        Image(systemName: image)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color(hex: color))
            .frame(width: 42, height: 42)
            .background(Color(hex: color).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct TeacherStudentEditorView: View {
    let student: TeacherLocalStudent?
    let repository: TeacherStudentsRepository
    @Environment(\.dismiss) private var dismiss
    @State private var studentID: String
    @State private var name: String
    @State private var className: String
    @State private var note: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(student: TeacherLocalStudent?, repository: TeacherStudentsRepository) {
        self.student = student
        self.repository = repository
        _studentID = State(initialValue: student?.publicID ?? "")
        _name = State(initialValue: student?.name ?? "")
        _className = State(initialValue: student?.className ?? "")
        _note = State(initialValue: student?.note ?? "")
    }

    var body: some View {
        TeacherWorkspaceScreen(
            title: student == nil ? "Добавить ученика" : "Редактировать ученика",
            subtitle: "Данные сохраняются только локально"
        ) {
            VStack(spacing: 14) {
                editorField("ID ученика *", placeholder: "Обязательное поле", text: $studentID, disabled: student != nil)
                if student != nil {
                    editorField("Имя", placeholder: "Имя ученика", text: $name)
                        .disabled(true)
                        .opacity(0.72)
                }
                editorField("Класс", placeholder: "Например, 9А", text: $className)
                editorField("Примечание", placeholder: "Необязательно", text: $note, axis: .vertical)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Сохранить")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "7257F4"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .buttonStyle(.plain)
                .disabled(normalizedID.isEmpty || isSaving)
                .opacity(normalizedID.isEmpty || isSaving ? 0.55 : 1)
            }
        }
    }

    private var normalizedID: String {
        studentID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func editorField(
        _ title: String,
        placeholder: String,
        text: Binding<String>,
        disabled: Bool = false,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
            TextField(placeholder, text: text, axis: axis)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .semibold))
                .padding(14)
                .frame(minHeight: 52)
                .background(disabled ? Color(hex: "F1F2F6") : .white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                }
                .disabled(disabled)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let now = Date()
        do {
            if let student {
                let value = TeacherLocalStudent(
                    id: student.id,
                    publicID: student.publicID,
                    name: student.name,
                    className: className.trimmingCharacters(in: .whitespacesAndNewlines),
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdAt: student.createdAt,
                    updatedAt: now
                )
                try await repository.saveStudent(value)
            } else {
                try await repository.addStudent(
                    publicID: normalizedID,
                    className: className,
                    note: note
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TeacherInviteStudentView: View {
    let repository: TeacherStudentsRepository
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var resultMessage: String?
    @State private var isError = false

    var body: some View {
        TeacherWorkspaceScreen(title: "Пригласить ученика", subtitle: "Приглашение придёт в уведомления") {
            VStack(spacing: 14) {
                inviteField("Email ученика", placeholder: "student@example.com", text: $email)
                inviteField("Сообщение", placeholder: "Напишите сообщение ученику", text: $message, axis: .vertical)

                if let resultMessage {
                    Text(resultMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: isError ? "FF3B30" : "35B76B"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Text("Пригласить")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "7257F4"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .buttonStyle(.plain)
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .opacity(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.55 : 1)
            }
        }
    }

    private func inviteField(_ title: String, placeholder: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
            TextField(placeholder, text: text, axis: axis)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .semibold))
                .padding(14)
                .frame(minHeight: 52)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                }
        }
    }

    private func send() async {
        isSending = true
        defer { isSending = false }
        do {
            try await repository.inviteStudent(email: email, message: message)
            email = ""
            message = ""
            isError = false
            resultMessage = "Приглашение отправлено"
        } catch {
            isError = true
            resultMessage = error.localizedDescription
        }
    }
}
