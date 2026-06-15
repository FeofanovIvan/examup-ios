import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct TeacherAssignmentConstructorView: View {
    @StateObject private var viewModel: TeacherAssignmentConstructorViewModel
    @State private var isAttachmentImporterPresented = false
    @State private var showsDatasetDialog = false
    @State private var showsQuestionDialog = false
    @State private var showsTimerDialog = false
    @State private var showsStudentDialog = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: TeacherAssignmentConstructorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                teacherConstructorHeader

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    teacherSettingsCard
                    teacherBuilderCard
                    teacherSummaryCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color(hex: "FBFCFF").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showsDatasetDialog) {
            teacherDatasetDialog
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsQuestionDialog) {
            teacherQuestionDialog
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsTimerDialog) {
            teacherTimerDialog
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsStudentDialog) {
            teacherStudentDialog
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fileImporter(
            isPresented: $isAttachmentImporterPresented,
            allowedContentTypes: TeacherAssignmentAttachmentPicker.allowedContentTypes
        ) { result in
            loadAttachment(from: result)
        }
    }

    private var teacherConstructorHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(teacherInk)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("Конструктор")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(teacherInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("Соберите задание для ученика")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(teacherMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private var teacherSettingsCard: some View {
        teacherConstructorCard {
            VStack(alignment: .leading, spacing: 13) {
                teacherSectionTitle("1. Настройка варианта")

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 7) {
                        teacherFieldLabel("clock", "Таймер")
                        Button {
                            showsTimerDialog = true
                        } label: {
                            VStack(spacing: 2) {
                                HStack {
                                    Text(viewModel.formattedDuration)
                                        .font(.system(size: 19, weight: .bold, design: .rounded))
                                        .foregroundStyle(teacherInk)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(teacherInk)
                                }
                                Text("чч : мм")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: "8A91A3"))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 58)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        teacherFieldLabel("list.bullet.rectangle", "Количество")
                        HStack(spacing: 6) {
                            teacherCountButton(systemName: "minus", isDisabled: viewModel.questionCount <= 1) {
                                viewModel.decreaseQuestionCount()
                            }

                            Text("\(viewModel.questionCount)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(teacherInk)
                                .frame(maxWidth: .infinity)

                            teacherCountButton(systemName: "plus", isDisabled: viewModel.questionCount >= 50) {
                                viewModel.increaseQuestionCount()
                            }
                        }
                        .padding(6)
                        .frame(height: 58)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                        )

                        Text("Максимум: 50")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "8A91A3"))
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    teacherFieldLabel("person.crop.circle.fill", "Ученик")
                    Button {
                        showsStudentDialog = true
                    } label: {
                        teacherFlatSelectionRow(value: teacherSelectedStudentDisplayTitle, icon: "person.fill")
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 7) {
                    teacherFieldLabel("calendar.badge.clock", "Выполнить до")
                    DatePicker(
                        "Дата и время",
                        selection: $viewModel.publishDraft.dueAt,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var teacherBuilderCard: some View {
        teacherConstructorCard {
            VStack(alignment: .leading, spacing: 12) {
                teacherSectionTitle("2. Выбор заданий")
                teacherSlotScroller
                teacherExamSelector
                teacherQuestionSelectionArea
            }
        }
    }

    private var teacherSlotScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<viewModel.questionCount, id: \.self) { index in
                    let isSelected = viewModel.selectedSlotIndex == index
                    let isFilled = index < viewModel.selectedCount

                    Button {
                        viewModel.selectSlot(index)
                    } label: {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSelected ? .white : teacherInk)
                            .frame(width: 40, height: 40)
                            .background(isSelected ? teacherSlotGradient : LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? teacherAccent.opacity(0.18) : Color(hex: "E4E7F0"), lineWidth: 1)
                            )
                            .overlay(alignment: .topTrailing) {
                                if isFilled {
                                    Circle()
                                        .fill(teacherSuccess)
                                        .frame(width: 8, height: 8)
                                        .offset(x: -3, y: 4)
                                }
                            }
                            .shadow(color: isSelected ? teacherAccent.opacity(0.18) : .clear, radius: 8, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 3)
        }
    }

    private var teacherExamSelector: some View {
        Button {
            showsDatasetDialog = true
        } label: {
            teacherFlatSelectionRow(value: teacherSelectedDatasetDisplayTitle, icon: "book.closed.fill")
        }
        .buttonStyle(.plain)
        .disabled(viewModel.datasetOptions.isEmpty)
    }

    private var teacherQuestionSelectionArea: some View {
        VStack(alignment: .leading, spacing: 11) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "EF4444"))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "FFF0F1"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if viewModel.isCustomQuestionMode {
                customQuestionInlineEditor
            } else {
                Button {
                    showsQuestionDialog = true
                } label: {
                    teacherFlatSelectionRow(value: teacherSelectedQuestionDisplayTitle, icon: "list.bullet.rectangle")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.questionGroups.isEmpty)

                if let task = viewModel.currentTask {
                    TeacherTaskPreview(task: task)
                    teacherQuestionNavigation
                }
            }

            Button {
                if viewModel.isCustomQuestionMode {
                    viewModel.addCustomDraft()
                } else {
                    viewModel.addCurrentSeedTask()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                        .background(teacherButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text("Добавить вопрос в вариант")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(teacherAccent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(teacherAccent.opacity(0.72), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isCustomQuestionMode ? !viewModel.canAddCustomDraft : viewModel.currentTask == nil)
            .opacity((viewModel.isCustomQuestionMode ? viewModel.canAddCustomDraft : viewModel.currentTask != nil) ? 1 : 0.55)
        }
    }

    private var teacherQuestionNavigation: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.showPreviousTaskInGroup()
            } label: {
                Label("Предыдущий вопрос", systemImage: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(teacherInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: "F8FAFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showNextTaskInGroup()
            } label: {
                Label("Следующий вопрос", systemImage: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(teacherInk)
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: "F8FAFF"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var customQuestionInlineEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            teacherFlatSelectionRow(value: "Свой вопрос. Заполните поля вручную", icon: "square.and.pencil")

            TeacherLatexEditor(title: "Задание", placeholder: "Введите текст задания", text: $viewModel.customDraft.taskText, minHeight: 96)
            TeacherLatexEditor(title: "Ответ", placeholder: "Введите правильный ответ", text: $viewModel.customDraft.answerText, minHeight: 70)
            TeacherLatexEditor(title: "Пояснение", placeholder: "Необязательно", text: $viewModel.customDraft.explanationText, minHeight: 76)

            Button {
                isAttachmentImporterPresented = true
            } label: {
                Label(viewModel.customDraft.attachment?.filename ?? "Добавить файл или чертеж", systemImage: "paperclip")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(teacherAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: "F6F1FF"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var teacherSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Итоговая информация")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(teacherSuccess)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                alignment: .leading,
                spacing: 10
            ) {
                teacherSummaryMetric(systemName: "timer", title: viewModel.formattedDuration, subtitle: "Таймер")
                teacherSummaryMetric(systemName: "list.bullet", title: "\(viewModel.selectedCount)/\(viewModel.questionCount)", subtitle: "Вопросы")
                teacherSummaryMetric(systemName: "person.2.fill", title: "\(viewModel.publishDraft.studentIDs.count)", subtitle: "Ученики")
                teacherSummaryMetric(systemName: "calendar.badge.clock", title: teacherDueDateTitle, subtitle: "Выполнить до")
            }

            Button {
                Task { await viewModel.publish() }
            } label: {
                Text(viewModel.isPublishing ? "Создаем назначение" : "Назначить")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(viewModel.canPublish ? teacherSuccess : Color(hex: "C6CCD8"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canPublish)

            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(teacherSuccess)
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(hex: "F2FFF6"), Color(hex: "FBFFFC")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "D7F3DF"), lineWidth: 1)
        )
    }

    private var teacherDatasetDialog: some View {
        VStack(spacing: 0) {
            teacherDialogHeader(title: "Выбор экзамена", subtitle: "ЕГЭ, ОГЭ, ВПР или свой вопрос")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.datasetOptions) { option in
                        Button {
                            Task {
                                await viewModel.selectDataset(option)
                                showsDatasetDialog = false
                            }
                        } label: {
                            teacherDialogOptionRow(
                                title: teacherDatasetDialogTitle(option),
                                subtitle: option.subtitle,
                                isSelected: viewModel.selectedDatasetID == option.datasetID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .background(Color(hex: "FBFCFF"))
    }

    private var teacherQuestionDialog: some View {
        VStack(spacing: 0) {
            teacherDialogHeader(title: "Выбор вопроса", subtitle: "Номер задания и тема из базы")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.questionGroups) { group in
                        Button {
                            viewModel.selectQuestionGroup(group)
                            showsQuestionDialog = false
                        } label: {
                            teacherDialogOptionRow(
                                title: "Вопрос \(group.questionNumber)",
                                subtitle: group.topic,
                                isSelected: viewModel.selectedGroupID == group.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .background(Color(hex: "FBFCFF"))
    }

    private var teacherStudentDialog: some View {
        VStack(spacing: 0) {
            teacherDialogHeader(title: "Выбор ученика", subtitle: "Ученики из списка преподавателя")

            ScrollView {
                VStack(spacing: 10) {
                    if viewModel.availableStudents.isEmpty {
                        Text("Список учеников пока пуст. Добавьте ученика в кабинете преподавателя.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(teacherMuted)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        ForEach(viewModel.availableStudents) { student in
                            Button {
                                viewModel.setSelectedStudentID(student.id)
                                showsStudentDialog = false
                            } label: {
                                teacherDialogOptionRow(
                                    title: student.displayName,
                                    subtitle: "ID \(student.publicID)",
                                    isSelected: viewModel.publishDraft.studentIDs.contains(student.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .background(Color(hex: "FBFCFF"))
    }

    private var teacherTimerDialog: some View {
        VStack(alignment: .leading, spacing: 18) {
            teacherDialogHeader(title: "Таймер", subtitle: "Укажите время на выполнение задания")
                .padding(.horizontal, -18)
                .padding(.top, -8)
                .padding(.bottom, -4)

            HStack(spacing: 12) {
                teacherTimerStepper(
                    title: "Часы",
                    value: viewModel.durationHours,
                    range: 0...5,
                    decrease: {
                        viewModel.setDuration(hours: viewModel.durationHours - 1, minutes: viewModel.durationMinutes)
                    },
                    increase: {
                        viewModel.setDuration(hours: viewModel.durationHours + 1, minutes: viewModel.durationMinutes)
                    }
                )

                teacherTimerStepper(
                    title: "Минуты",
                    value: viewModel.durationMinutes,
                    range: 0...55,
                    decrease: {
                        viewModel.setDuration(hours: viewModel.durationHours, minutes: viewModel.durationMinutes - 5)
                    },
                    increase: {
                        viewModel.setDuration(hours: viewModel.durationHours, minutes: viewModel.durationMinutes + 5)
                    }
                )
            }

            Button {
                showsTimerDialog = false
            } label: {
                Text("Готово")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(teacherButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .background(Color(hex: "FBFCFF"))
    }

    private var teacherSelectedDatasetDisplayTitle: String {
        guard let option = viewModel.selectedDatasetOption else {
            return "Не выбран"
        }

        if option.datasetID == TeacherAssignmentConstructorViewModel.customQuestionDatasetID {
            return option.title
        }

        let category = teacherCategoryTitle(option.category)
        if option.title.caseInsensitiveCompare(category) == .orderedSame {
            return option.title
        }
        return "\(category) \(option.title)"
    }

    private var teacherSelectedQuestionDisplayTitle: String {
        guard let group = viewModel.selectedQuestionGroup else {
            return viewModel.questionGroups.isEmpty ? "Нет доступных вопросов" : "Выберите вопрос и тему"
        }

        let position = viewModel.selectedGroupTaskIndex + 1
        return "Вопрос \(group.questionNumber). \(group.topic)  \(position)/\(group.tasks.count)"
    }

    private var teacherSelectedStudentDisplayTitle: String {
        viewModel.selectedStudentDisplayTitle
    }

    private var teacherDueDateTitle: String {
        viewModel.publishDraft.dueAt.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }

    private func teacherSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(teacherAccent)
    }

    private func teacherFieldLabel(_ icon: String, _ title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(teacherMuted)
    }

    private func teacherCountButton(systemName: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isDisabled ? Color(hex: "C2C8D4") : teacherInk)
                .frame(width: 40, height: 42)
                .background(Color(hex: "F8FAFF"))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func teacherTimerStepper(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        decrease: @escaping () -> Void,
        increase: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(teacherMuted)

            HStack(spacing: 7) {
                teacherCountButton(systemName: "minus", isDisabled: value <= range.lowerBound, action: decrease)

                Text(String(format: "%02d", value))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(teacherInk)
                    .frame(maxWidth: .infinity)

                teacherCountButton(systemName: "plus", isDisabled: value >= range.upperBound, action: increase)
            }
            .padding(6)
            .frame(height: 58)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
            )
        }
    }

    private func teacherFlatSelectionRow(value: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(teacherAccent)
                .frame(width: 28)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(teacherInk)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(teacherInk)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 50)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
        )
    }

    private func teacherDialogHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(teacherInk)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(teacherMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    private func teacherDialogOptionRow(title: String, subtitle: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(teacherInk)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(teacherMuted)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(isSelected ? teacherAccent : Color(hex: "C2C8D4"))
        }
        .padding(14)
        .background(isSelected ? Color(hex: "F4F0FF") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? teacherAccent.opacity(0.28) : Color(hex: "E4E7F0"), lineWidth: 1)
        )
    }

    private func teacherSummaryMetric(systemName: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(teacherSuccess)
                .frame(width: 36, height: 36)
                .background(Color(hex: "DDF8E5"))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(teacherInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(teacherMuted)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func teacherConstructorCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(hex: "E8E2FF"), lineWidth: 1)
            )
            .shadow(color: Color(hex: "9CA8C6").opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func teacherDatasetDialogTitle(_ option: ExamConstructorDatasetOption) -> String {
        if option.datasetID == TeacherAssignmentConstructorViewModel.customQuestionDatasetID {
            return option.title
        }

        let category = teacherCategoryTitle(option.category)
        if option.title.caseInsensitiveCompare(category) == .orderedSame {
            return option.title
        }
        return "\(category) \(option.title)"
    }

    private func teacherCategoryTitle(_ category: ExamCategory) -> String {
        switch category {
        case .ege:
            return "ЕГЭ"
        case .oge:
            return "ОГЭ"
        case .vpr:
            return "ВПР"
        case .constructor:
            return "Свой вопрос"
        }
    }

    private var teacherAccent: Color { Color(hex: "7257F4") }
    private var teacherSuccess: Color { Color(hex: "35C467") }
    private var teacherInk: Color { Color(hex: "171B2A") }
    private var teacherMuted: Color { Color(hex: "687083") }

    private var teacherSlotGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "C8B8FF"), Color(hex: "8D75FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var teacherButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "7A61F6"), Color(hex: "5E3FE6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func loadAttachment(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let originalData = try Data(contentsOf: url)
            let prepared = try TeacherAssignmentAttachmentPicker.prepare(url: url, data: originalData)
            viewModel.setCustomAttachment(
                data: prepared.data,
                filename: prepared.filename,
                contentType: prepared.contentType,
                originalBytes: originalData.count
            )
        } catch {
            viewModel.setCustomAttachmentError(error.localizedDescription)
        }
    }

    private var datasetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("База заданий")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.datasetOptions) { option in
                        Button {
                            Task { await viewModel.selectDataset(option) }
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                Text(option.subtitle)
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(viewModel.selectedDatasetID == option.datasetID ? .white : Color(hex: "17213A"))
                            .padding(.horizontal, 12)
                            .frame(height: 52)
                            .background(viewModel.selectedDatasetID == option.datasetID ? Color(hex: "7257F4") : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "E7E9F1"), lineWidth: viewModel.selectedDatasetID == option.datasetID ? 0 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var customTaskEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            TeacherSectionTitle(title: "Кастомное задание", subtitle: "Задание и ответ обязательны")

            TeacherLatexEditor(title: "Задание", placeholder: "Введите текст задания", text: $viewModel.customDraft.taskText, minHeight: 96)

            TeacherLatexEditor(title: "Ответ", placeholder: "Введите правильный ответ", text: $viewModel.customDraft.answerText, minHeight: 70)

            TeacherLatexEditor(title: "Пояснение", placeholder: "Необязательно", text: $viewModel.customDraft.explanationText, minHeight: 76)

            HStack(spacing: 10) {
                let attachment = viewModel.customDraft.attachment

                Button {
                    isAttachmentImporterPresented = true
                } label: {
                    Label(attachment == nil ? "Добавить файл" : attachment?.filename ?? "Файл выбран", systemImage: "paperclip")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "F6F1FF"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    viewModel.addCustomDraft()
                } label: {
                    Label("Добавить", systemImage: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "35B76B"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canAddCustomDraft)
                .opacity(viewModel.canAddCustomDraft ? 1 : 0.5)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private var selectedItems: some View {
        VStack(alignment: .leading, spacing: 10) {
            TeacherSectionTitle(title: "Выбрано", subtitle: "\(viewModel.selectedCount) заданий")

            if viewModel.selectedCount == 0 {
                Text("Добавьте задания из базы или создайте custom-задание.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
            }

            ForEach(viewModel.selectedSeedItems) { item in
                TeacherSelectedItemRow(
                    title: "\(item.title) · \(item.subtitle)",
                    subtitle: "Из базы",
                    systemImage: "doc.text",
                    tintHex: "7257F4"
                ) {
                    viewModel.removeSeedItem(id: item.id)
                }
            }

            ForEach(Array(viewModel.customDrafts.enumerated()), id: \.offset) { index, draft in
                TeacherSelectedItemRow(
                    title: draft.trimmedTaskText,
                    subtitle: "Кастомное задание",
                    systemImage: draft.attachment == nil ? "text.alignleft" : "paperclip",
                    tintHex: "35B76B"
                ) {
                    viewModel.removeCustomDraft(at: IndexSet(integer: index))
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private var publishPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            TeacherSectionTitle(title: "Назначение", subtitle: "Firestore + Storage")

            TextField("Название работы", text: $viewModel.publishDraft.title)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(hex: "F7F8FC"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            TextField("ID учеников через пробел или запятую", text: $viewModel.publishDraft.studentIDsText, axis: .vertical)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(2, reservesSpace: true)
                .padding(12)
                .background(Color(hex: "F7F8FC"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "FF3B30"))
            }

            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "35B76B"))
            }

            Button {
                Task { await viewModel.publish() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isPublishing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text("Назначить ученикам")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "7257F4"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canPublish)
            .opacity(viewModel.canPublish ? 1 : 0.55)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }
}

private struct TeacherSeedTaskPicker: View {
    @ObservedObject var viewModel: TeacherAssignmentConstructorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TeacherSectionTitle(title: "Выбор задания", subtitle: "\(viewModel.currentTasks.count) доступно")

            if !viewModel.questionGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.questionGroups) { group in
                            Button {
                                viewModel.selectQuestionGroup(group)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(group.title)
                                        .font(.system(size: 13, weight: .bold))
                                        .lineLimit(1)
                                    Text(group.subtitle)
                                        .font(.system(size: 11, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(viewModel.selectedGroupID == group.id ? .white : Color(hex: "17213A"))
                                .padding(.horizontal, 12)
                                .frame(height: 52)
                                .background(viewModel.selectedGroupID == group.id ? Color(hex: "7257F4") : Color(hex: "F7F8FC"))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let task = viewModel.currentTask, let group = viewModel.selectedQuestionGroup {
                TeacherTaskPreview(task: task)

                HStack(spacing: 10) {
                    Button {
                        viewModel.showPreviousTaskInGroup()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "17213A"))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "F7F8FC"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 2) {
                        Text(group.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(hex: "17213A"))
                        Text("\(viewModel.selectedGroupTaskIndex + 1) из \(group.tasks.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "687083"))
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        viewModel.showNextTaskInGroup()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "17213A"))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "F7F8FC"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    viewModel.addCurrentSeedTask()
                } label: {
                    Label("Добавить это задание", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "7257F4"))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Text("В выбранной базе пока нет заданий.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }
}

private struct TeacherTaskPreview: View {
    let task: EducationalTask
    @State private var questionHeight: CGFloat = 140
    @State private var explanationHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(task.topic)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "17213A"))

            VStack(alignment: .leading, spacing: 6) {
                Text("Текст вопроса")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "687083"))

                ExamHTMLWebView(
                    content: ExamContentRendering.unifiedHTML(
                        primaryHTML: task.questionHTML,
                        drawingURL: task.drawingURL
                    ),
                    baseURL: resourceBaseURL,
                    height: $questionHeight
                )
                    .frame(height: max(questionHeight, 120))
                    .id("question-\(task.id)")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Ответ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "687083"))

                ExamAnswerDisplayView(
                    answer: task.answer,
                    drawingURL: task.answerDrawingURL,
                    resourceBaseURL: resourceBaseURL,
                    emptyMessage: task.explanationHTML?.trimmedExamHTML.isEmpty == false
                        ? "Развёрнутый ответ приведён в пояснении ниже"
                        : "Ответ не указан"
                )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: "F7F8FC"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let explanationHTML = task.explanationHTML?.renderableExamExplanationHTML, !explanationHTML.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Пояснение")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "687083"))

                    ExamHTMLWebView(
                        content: ExamContentRendering.unifiedHTML(
                            primaryHTML: explanationHTML,
                            drawingURL: task.explanationDrawingURL
                        ),
                        baseURL: resourceBaseURL,
                        revealsHiddenContent: true,
                        height: $explanationHeight
                    )
                    .frame(height: max(explanationHeight, 100))
                        .id("explanation-\(task.id)")
                }
            }

            if task.explanationHTML?.renderableExamExplanationHTML.trimmedExamHTML.isEmpty != false,
               let explanationDrawingURL = task.explanationDrawingURL {
                ExamHTMLWebView(
                    content: ExamContentRendering.unifiedHTML(
                        primaryHTML: "",
                        drawingURL: explanationDrawingURL
                    ),
                    baseURL: resourceBaseURL,
                    height: $explanationHeight
                )
                .frame(height: max(explanationHeight, 100))
                .id("explanation-drawing-\(task.id)")
            }
        }
    }

    private var resourceBaseURL: URL? {
        SubjectLibraryCatalog.resourceBaseURL(for: task.subjectID) ?? Bundle.main.resourceURL
    }
}

private struct TeacherSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "17213A"))
            Spacer(minLength: 8)
            Text(subtitle)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))
        }
    }
}

private struct TeacherLatexEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    @State private var isEditorPresented = false
    @State private var previewHeight: CGFloat = 76

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "687083"))
                Spacer()
                Image(systemName: "function")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
            }

            Button {
                isEditorPresented = true
            } label: {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: "9AA1AF"))
                            .padding(14)
                    } else {
                        ExamLatexAnswerWebView(
                            latex: text,
                            keepsActiveFormulaOnOneLine: false,
                            height: $previewHeight
                        )
                        .frame(minHeight: max(minHeight, previewHeight))
                        .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
                .background(Color(hex: "F7F8FC"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isEditorPresented) {
            TeacherLatexEditorSheet(title: title, placeholder: placeholder, text: $text)
        }
    }
}

private struct TeacherLatexEditorSheet: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @State private var inputMode: ExamAnswerInputMode = .russian
    @State private var inputEngine: ExamLatexInputEngine
    @State private var previewHeight: CGFloat = 96

    init(title: String, placeholder: String, text: Binding<String>) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        var engine = ExamLatexInputEngine()
        engine.restore(text.wrappedValue)
        _inputEngine = State(initialValue: engine)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if inputEngine.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "9AA1AF"))
                            .padding(16)
                    } else {
                        ExamLatexAnswerWebView(
                            latex: inputEngine.latexForRendering,
                            keepsActiveFormulaOnOneLine: inputEngine.keepsActiveFormulaOnOneLine,
                            height: $previewHeight
                        )
                        .frame(minHeight: max(previewHeight, 110))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "E1E5EF"), lineWidth: 1)
                }
                .padding(.horizontal, 12)

                HStack(spacing: 10) {
                    ExamKeyboardModePicker(selectedMode: inputMode, onSelect: selectInputMode)

                    Button(action: pasteFromClipboard) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(hex: "7257F4"))
                            .frame(width: 42, height: 38)
                            .background(Color(hex: "F4F0FF"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)

                Spacer(minLength: 0)

                ExamAnswerKeyboard(
                    mode: inputMode,
                    containerWidth: UIScreen.main.bounds.width,
                    showsDraft: false,
                    onModeSelect: selectInputMode,
                    onDraft: {},
                    onInput: appendValue,
                    onDelete: deleteValue,
                    onClear: clear,
                    onMoveCursorRight: moveCursorRight
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .background(Color(hex: "F7F8FC"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        syncText()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                prepareInputForCurrentMode()
            }
        }
    }

    private func selectInputMode(_ mode: ExamAnswerInputMode) {
        inputMode = mode
        prepareInputForCurrentMode()
    }

    private func prepareInputForCurrentMode() {
        switch inputMode {
        case .math:
            inputEngine.closeTextIfNeeded()
        case .russian, .english:
            inputEngine.openTextIfNeeded()
        }
        syncText()
    }

    private func appendValue(_ value: String) {
        if value == "\n" {
            inputEngine.insertLineBreak()
        } else {
            switch inputMode {
            case .math:
                inputEngine.insertMathSymbol(value)
            case .russian, .english:
                inputEngine.insertText(value)
            }
        }
        syncText()
    }

    private func pasteFromClipboard() {
        guard let value = UIPasteboard.general.string, !value.isEmpty else { return }
        appendValue(value)
    }

    private func deleteValue() {
        inputEngine.delete()
        syncText()
    }

    private func clear() {
        inputEngine.clear()
        prepareInputForCurrentMode()
    }

    private func moveCursorRight() {
        inputEngine.moveCursorRight()
        syncText()
    }

    private func syncText() {
        text = inputEngine.latexForSaving
    }
}

private struct TeacherTextFieldRow: View {
    let title: String
    let systemImage: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "687083"))

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "171B2A"))
                .lineLimit(2, reservesSpace: true)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                )
        }
    }
}

private struct TeacherSelectedItemRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tintHex: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: tintHex))
                .frame(width: 38, height: 38)
                .background(Color(hex: tintHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "17213A"))
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
            }

            Spacer(minLength: 0)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "FF3B30"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "FFF0EF"))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(hex: "F7F8FC"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private enum TeacherAssignmentAttachmentPicker {
    static var allowedContentTypes: [UTType] {
        [
            .image,
            .pdf,
            UTType(filenameExtension: "doc"),
            UTType(filenameExtension: "docx")
        ].compactMap { $0 }
    }

    static func prepare(url: URL, data: Data) throws -> TeacherAssignmentPreparedAttachment {
        let filename = url.lastPathComponent.isEmpty ? "attachment" : url.lastPathComponent
        let type = UTType(filenameExtension: url.pathExtension)
        if type?.conforms(to: .image) == true {
            return try compressedImageAttachment(data: data, fallbackFilename: filename)
        }

        return TeacherAssignmentPreparedAttachment(
            data: data,
            filename: filename,
            contentType: contentType(for: type, pathExtension: url.pathExtension)
        )
    }

    private static func compressedImageAttachment(
        data: Data,
        fallbackFilename: String
    ) throws -> TeacherAssignmentPreparedAttachment {
        guard let image = UIImage(data: data),
              let resized = image.teacherAssignmentResized(maxDimension: 1_600),
              let compressedData = resized.jpegData(compressionQuality: 0.74) else {
            throw TeacherAssignmentAttachmentError.unreadableImage
        }

        let baseName = fallbackFilename
            .split(separator: ".")
            .dropLast()
            .joined(separator: ".")
        let filename = (baseName.isEmpty ? "image" : baseName) + ".jpg"
        return TeacherAssignmentPreparedAttachment(
            data: compressedData,
            filename: filename,
            contentType: "image/jpeg"
        )
    }

    private static func contentType(for type: UTType?, pathExtension: String) -> String {
        if let preferred = type?.preferredMIMEType {
            return preferred
        }

        switch pathExtension.lowercased() {
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }
}

private struct TeacherAssignmentPreparedAttachment {
    let data: Data
    let filename: String
    let contentType: String
}

private enum TeacherAssignmentAttachmentError: LocalizedError {
    case unreadableImage

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "Не удалось прочитать изображение"
        }
    }
}

private extension UIImage {
    func teacherAssignmentResized(maxDimension: CGFloat) -> UIImage? {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

struct TeacherAssignmentHistoryView: View {
    @StateObject private var viewModel: TeacherAssignmentHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    private let title: String
    private let subtitle: String

    init(
        viewModel: TeacherAssignmentHistoryViewModel,
        title: String = "История заданий",
        subtitle: String = "Сроки, статусы и результаты учеников"
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                listActions

                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
                } else if viewModel.filteredAssignments.isEmpty {
                    TeacherInfoCard(
                        systemImage: "clock.arrow.circlepath",
                        tintHex: "FF8A1F",
                        title: "Заданий пока нет",
                        subtitle: "Созданные задания и их статусы появятся здесь."
                    )
                } else {
                    ForEach(viewModel.filteredAssignments) { item in
                        historyCard(item)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF4D55"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.load() } }
        .sheet(item: $viewModel.resultReport) { report in
            ExamResultReportView(report: report) {
                viewModel.resultReport = nil
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .frame(width: 42, height: 42)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
    }

    private var listActions: some View {
        HStack(spacing: 10) {
            historyActionButton(title: "Фильтр", systemImage: "line.3.horizontal.decrease")
            historyActionButton(title: "Сортировка", systemImage: "arrow.up.arrow.down")
        }
    }

    private func historyActionButton(title: String, systemImage: String) -> some View {
        Button {
            // Filter and sorting behavior will be connected when their options are defined.
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "E3E6EF"), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func historyCard(_ item: TeacherAssignmentHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.isSubmitted ? "checkmark.seal.fill" : "doc.text.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(statusTint(item))
                    .frame(width: 48, height: 48)
                    .background(statusTint(item).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                    Text("\(item.studentName) · ID \(item.studentPublicID)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "7B8194"))
                        .lineLimit(1)
                }

                Spacer()

                Text(item.isSubmitted ? "Сдано" : "Не сдано")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(statusTint(item))
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(statusTint(item).opacity(0.12))
                    .clipShape(Capsule())
            }

            Label("Сдать до \(dateTitle(item.dueAt))", systemImage: "calendar.badge.clock")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "687083"))

            if let submittedAt = item.submittedAt {
                HStack {
                    Label("Сдано \(dateTitle(submittedAt))", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "22A95A"))

                    Spacer()

                    Button {
                        viewModel.showResult(for: item)
                    } label: {
                        Text("Результат")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "7257F4"))
                            .padding(.horizontal, 12)
                            .frame(height: 38)
                            .background(Color(hex: "F4F0FF"))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(item.isSubmitted ? Color(hex: "F4FCF7") : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(item.isSubmitted ? Color(hex: "C7EBD3") : Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private func statusTint(_ item: TeacherAssignmentHistoryItem) -> Color {
        item.isSubmitted ? Color(hex: "22A95A") : Color(hex: "F28A2E")
    }

    private func dateTitle(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year().hour().minute().locale(Locale(identifier: "ru_RU")))
    }
}

struct TeacherWorkspaceScreen<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                content
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "17213A"))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "17213A"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
    }
}

struct TeacherInfoCard: View {
    let systemImage: String
    let tintHex: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: tintHex))
                .frame(width: 48, height: 48)
                .background(Color(hex: tintHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "17213A"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
