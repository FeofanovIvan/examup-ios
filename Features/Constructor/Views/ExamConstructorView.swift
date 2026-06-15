import SwiftUI

struct ExamConstructorView: View {
    @StateObject private var viewModel: ExamConstructorViewModel
    @State private var showsDatasetDialog = false
    @State private var showsQuestionDialog = false
    @State private var showsTimerDialog = false
    let onStart: (ExamConstructorStartContext) -> Void
    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: ExamConstructorViewModel,
        onStart: @escaping (ExamConstructorStartContext) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onStart = onStart
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header
                settingsCard
                builderCard
                summaryCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color(hex: "FBFCFF").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showsDatasetDialog) {
            datasetDialog
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsQuestionDialog) {
            questionDialog
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsTimerDialog) {
            timerDialog
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }
}

private extension ExamConstructorView {
    var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ink)
                    .frame(width: 38, height: 38)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Конструктор")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("Создай свой вариант и тренируйся эффективно")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    var settingsCard: some View {
        constructorCard {
            VStack(alignment: .leading, spacing: 13) {
                sectionTitle("1. Настройка варианта")

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("clock", "Таймер")
                        Button {
                            showsTimerDialog = true
                        } label: {
                            VStack(spacing: 2) {
                                HStack {
                                    Text(viewModel.formattedDuration)
                                        .font(.system(size: 19, weight: .bold, design: .rounded))
                                        .foregroundStyle(ink)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(ink)
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
                        fieldLabel("list.bullet.rectangle", "Количество")
                        HStack(spacing: 6) {
                            countButton(systemName: "minus", isDisabled: viewModel.questionCount <= 1) {
                                viewModel.decreaseQuestionCount()
                            }

                            Text("\(viewModel.questionCount)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(ink)
                                .frame(maxWidth: .infinity)

                            countButton(systemName: "plus", isDisabled: viewModel.questionCount >= 50) {
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
            }
        }
    }

    var builderCard: some View {
        constructorCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("2. Выбор заданий")
                slotScroller
                examSelector
                questionSelectionArea
            }
        }
    }

    var examSelector: some View {
        Button {
            showsDatasetDialog = true
        } label: {
            flatSelectionRow(
                value: selectedDatasetDisplayTitle,
                icon: "book.closed.fill"
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.datasetOptions.isEmpty)
    }

    var slotScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<viewModel.questionCount, id: \.self) { index in
                    let isSelected = viewModel.selectedSlotIndex == index
                    let isFilled = viewModel.selectedOptionsBySlot[index] != nil
                    Button {
                        viewModel.selectSlot(index)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isSelected ? .white : ink)
                                .frame(width: 40, height: 40)
                                .background(isSelected ? slotGradient : LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? accent.opacity(0.18) : Color(hex: "E4E7F0"), lineWidth: 1)
                                )
                                .shadow(color: isSelected ? accent.opacity(0.18) : .clear, radius: 8, x: 0, y: 5)

                            if isFilled {
                                Circle()
                                    .fill(success)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -3, y: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 3)
        }
    }

    var questionSelectionArea: some View {
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

            Button {
                showsQuestionDialog = true
            } label: {
                flatSelectionRow(
                    value: selectedQuestionDisplayTitle,
                    icon: "list.bullet.rectangle"
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.options.isEmpty)

            Button {
                viewModel.addSelectedQuestion()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                        .background(buttonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text("Добавить вопрос в вариант")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(accent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accent.opacity(0.72), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                )
            }
            .disabled(viewModel.selectedOptionID == nil)
            .opacity(viewModel.selectedOptionID == nil ? 0.55 : 1)
        }
    }

    var datasetDialog: some View {
        VStack(spacing: 0) {
            dialogHeader(title: "Выбор экзамена", subtitle: "ЕГЭ, ОГЭ и будущие варианты ВПР")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.datasetOptions) { option in
                        Button {
                            Task {
                                await viewModel.selectDataset(option)
                                showsDatasetDialog = false
                            }
                        } label: {
                            dialogOptionRow(
                                title: datasetDialogTitle(option),
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

    var questionDialog: some View {
        VStack(spacing: 0) {
            dialogHeader(title: "Выбор вопроса", subtitle: "Номер задания и тема из базы")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.options) { option in
                        Button {
                            viewModel.selectQuestionOption(option)
                            showsQuestionDialog = false
                        } label: {
                            dialogOptionRow(
                                title: "Вопрос \(option.questionNumber)",
                                subtitle: option.topic,
                                isSelected: viewModel.selectedOptionID == option.id
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

    var timerDialog: some View {
        VStack(alignment: .leading, spacing: 18) {
            dialogHeader(title: "Таймер", subtitle: "Укажите время на выполнение варианта")
                .padding(.horizontal, -18)
                .padding(.top, -8)
                .padding(.bottom, -4)

            HStack(spacing: 12) {
                timerStepper(
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

                timerStepper(
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
                    .background(buttonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .background(Color(hex: "FBFCFF"))
    }

    var selectedDatasetDisplayTitle: String {
        guard let option = viewModel.selectedDatasetOption else {
            return "Не выбран"
        }

        let category = categoryTitle(option.category)
        if option.title.caseInsensitiveCompare(category) == .orderedSame {
            return option.title
        }
        return "\(category) \(option.title)"
    }

    var selectedQuestionDisplayTitle: String {
        guard let option = viewModel.selectedQuestionOption else {
            return viewModel.options.isEmpty ? "Нет доступных вопросов" : "Выберите вопрос и тему"
        }
        return "Вопрос \(option.questionNumber). \(option.topic)"
    }

    @ViewBuilder
    var selectedVariantSummary: some View {
        if !viewModel.selectedOptionsBySlot.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Добавлено в вариант")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ink)

                VStack(spacing: 8) {
                    ForEach(viewModel.selectedOptionsBySlot.keys.sorted(), id: \.self) { slot in
                        if let option = viewModel.selectedOptionsBySlot[slot] {
                            selectedQuestionRow(slot: slot, option: option)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "9CA8C6").opacity(0.08), radius: 14, x: 0, y: 8)
        }
    }

    var topicPicker: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.filteredOptions) { option in
                    Button {
                        viewModel.selectedOptionID = option.id
                    } label: {
                        HStack(spacing: 10) {
                            Text(option.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(accent)
                                .frame(width: 52, alignment: .leading)

                            Text(option.subtitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ink)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: viewModel.selectedOptionID == option.id ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(viewModel.selectedOptionID == option.id ? accent : Color(hex: "C2C8D4"))
                        }
                        .padding(12)
                        .background(viewModel.selectedOptionID == option.id ? Color(hex: "F4F0FF") : Color(hex: "F8FAFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 260)
    }

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Итоговая информация")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(success)

            HStack(spacing: 10) {
                summaryMetric(systemName: "clock", title: viewModel.formattedDuration, subtitle: "Таймер")
                summaryMetric(systemName: "list.bullet", title: "Вопрос", subtitle: "\(viewModel.addedCount)/\(viewModel.questionCount)")

                Button {
                    onStart(viewModel.makeStartContext())
                } label: {
                    Text("Начать решение")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 110, height: 46)
                        .background(viewModel.canStart ? success : Color(hex: "C6CCD8"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!viewModel.canStart)
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

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(accent)
    }

    func fieldLabel(_ systemName: String, _ title: String) -> some View {
        Label(title, systemImage: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(muted)
    }

    func flatSelectionRow(value: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 28)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
        )
    }

    func selectionRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(Color(hex: "F1ECFF"))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(muted)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
        )
    }

    func datasetDialogTitle(_ option: ExamConstructorDatasetOption) -> String {
        let category = categoryTitle(option.category)
        if option.title.caseInsensitiveCompare(category) == .orderedSame {
            return option.title
        }
        return "\(category) \(option.title)"
    }

    func dialogHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(ink)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    func dialogOptionRow(title: String, subtitle: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(ink)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(muted)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(isSelected ? accent : Color(hex: "C2C8D4"))
        }
        .padding(14)
        .background(isSelected ? Color(hex: "F4F0FF") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? accent.opacity(0.28) : Color(hex: "E4E7F0"), lineWidth: 1)
        )
    }

    func categoryTitle(_ category: ExamCategory) -> String {
        switch category {
        case .ege:
            return "ЕГЭ"
        case .oge:
            return "ОГЭ"
        case .vpr:
            return "ВПР"
        case .constructor:
            return "Конструктор"
        }
    }

    func categoryIcon(_ category: ExamCategory) -> String {
        switch category {
        case .ege:
            return "graduationcap.fill"
        case .oge:
            return "book.closed.fill"
        case .vpr:
            return "square.grid.2x2.fill"
        case .constructor:
            return "plus.square.fill"
        }
    }

    func countButton(systemName: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isDisabled ? Color(hex: "C2C8D4") : ink)
                .frame(width: 40, height: 42)
                .background(Color(hex: "F8FAFF"))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color(hex: "E4E7F0"), lineWidth: 1)
                )
        }
        .disabled(isDisabled)
    }

    func timerStepper(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        decrease: @escaping () -> Void,
        increase: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(muted)

            HStack(spacing: 7) {
                countButton(systemName: "minus", isDisabled: value <= range.lowerBound, action: decrease)

                Text(String(format: "%02d", value))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)

                countButton(systemName: "plus", isDisabled: value >= range.upperBound, action: increase)
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

    func selectedQuestionRow(slot: Int, option: ExamConstructorQuestionOption) -> some View {
        HStack(spacing: 10) {
            Text("\(slot + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ink)
                Text(option.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button {
                viewModel.removeQuestion(at: slot)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "EF4444"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "FFF0F1"))
                    .clipShape(Circle())
            }
        }
        .padding(10)
        .background(Color(hex: "F8FAFF"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func summaryMetric(systemName: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(success)
                .frame(width: 36, height: 36)
                .background(Color(hex: "DDF8E5"))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func constructorCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    var accent: Color { Color(hex: "7257F4") }
    var success: Color { Color(hex: "35C467") }
    var ink: Color { Color(hex: "171B2A") }
    var muted: Color { Color(hex: "687083") }

    var slotGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "C8B8FF"), Color(hex: "8D75FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "7A61F6"), Color(hex: "5E3FE6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
