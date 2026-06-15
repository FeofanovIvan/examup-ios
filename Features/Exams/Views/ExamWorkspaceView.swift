import SwiftUI

struct ExamWorkspaceView: View {
    @StateObject var viewModel: ExamWorkspaceViewModel
    var onSubmitted: () async -> Void = {}
    /// Called when the user closes the result sheet and is fully done.
    /// The parent should pop to root here instead of relying on dismiss().
    var onFinished: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var isQuestionMenuOpen = false
    @State private var isAnswerPanelOpen = false
    @State private var isDraftOpen = false
    @State private var isExitConfirmationOpen = false
    @StateObject private var draftCanvasState = DrawingCanvasState()
    @State private var taskWebViewHeight: CGFloat = 1
    @State private var answerWebViewHeight: CGFloat = 64

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                topBar
                content
            }
            .background(Color(hex: "FBFCFF"))
            .disabled(isQuestionMenuOpen)

            if isQuestionMenuOpen {
                ExamQuestionSideMenu(
                    tasks: viewModel.tasks,
                    currentIndex: viewModel.currentTaskIndex,
                    answeredTaskIDs: Set(viewModel.savedAnswers.keys),
                    onSelect: { index in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            viewModel.selectTask(at: index)
                            isQuestionMenuOpen = false
                        }
                    },
                    onClose: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            isQuestionMenuOpen = false
                        }
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(3)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $isDraftOpen) {
            ExamDraftSheet(canvasState: draftCanvasState)
        }
        .sheet(isPresented: $isAnswerPanelOpen) {
            ExamAnswerUtilitySheet(
                answerText: viewModel.answerStorageText,
                taskNumber: viewModel.currentTaskNumber
            )
        }
        .sheet(item: $viewModel.resultReport) { report in
            ExamResultReportView(report: report) {
                viewModel.resultReport = nil
                onFinished()
            }
        }
        .confirmationDialog("Что сделать с экзаменом?", isPresented: $isExitConfirmationOpen, titleVisibility: .visible) {
            Button("Сохранить и выйти") {
                Task {
                    await viewModel.saveAndInterruptSession()
                    dismiss()
                }
            }

            Button("Завершить экзамен", role: .destructive) {
                Task {
                    await viewModel.finishSession(invalidateSafeSession: true)
                    await onSubmitted()
                }
            }

            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Текущий ответ будет сохранен локально.")
        }
        .alert("Есть незавершенный экзамен", isPresented: $viewModel.showsRestoredSessionWarning) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Вы можете продолжить эту сессию, но она больше не будет считаться выполненной в безопасном режиме.")
        }
        .alert("Время вышло", isPresented: $viewModel.showsTimeExpiredWarning) {
            Button("Закончить экзамен") {
                Task {
                    await viewModel.finishSession()
                    await onSubmitted()
                }
            }
            Button("Продолжить", role: .cancel) {}
        } message: {
            Text("Вы можете закончить экзамен сейчас. Фактическая длительность будет сохранена вместе с результатом.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    isQuestionMenuOpen.toggle()
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(examInk)
                    .frame(width: 38, height: 40)
                    .background(Color(hex: "F4F0FF"))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }

            topTabButton(.task)
            topTabButton(.answer)

            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(examPurple)
                .frame(width: 66, height: 38)
                .background(Color(hex: "F4F0FF"))
                .clipShape(Capsule())
        }
        .foregroundStyle(examInk)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.white)
    }

    private func topTabButton(_ tab: ExamWorkspaceTab) -> some View {
        Button {
            viewModel.saveCurrentAnswer()
            viewModel.selectedTab = tab
            if tab == .answer {
                viewModel.prepareInputForCurrentMode()
            }
        } label: {
            VStack(spacing: 5) {
                Text(tab.rawValue.uppercased())
                    .font(.system(size: 16, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Rectangle()
                    .fill(viewModel.selectedTab == tab ? examPurple : .clear)
                    .frame(height: 3)
            }
            .foregroundStyle(viewModel.selectedTab == tab ? examPurple : Color(hex: "9AA1AF"))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .task:
            taskContent
        case .answer:
            answerContent
        }
    }

    private var taskContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    if let task = viewModel.currentTask {
                        examProgressHeader

                        if let audioURL = task.audioURL, !audioURL.isEmpty {
                            ExamAudioPlayerView(source: audioURL)
                        }

                        ExamHTMLWebView(
                            content: ExamContentRendering.unifiedHTML(
                                primaryHTML: task.questionHTML,
                                drawingURL: task.drawingURL
                            ),
                            baseURL: resourceBaseURL(for: task.subjectID),
                            height: $taskWebViewHeight
                        )
                            .frame(height: max(taskWebViewHeight, 140))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            keyboardActionButtons
        }
        .background(.white)
    }

    private func resourceBaseURL(for subjectID: String) -> URL? {
        SubjectLibraryCatalog.resourceBaseURL(for: subjectID) ?? Bundle.main.resourceURL
    }

    private var answerContent: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("Задание № \(viewModel.currentTaskNumber)")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(examInk)

                    Spacer()

                    Button {
                        viewModel.continueFlow()
                    } label: {
                        Text("Ответить")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 122, height: 46)
                            .background(examPurple)
                            .clipShape(Capsule())
                            .shadow(color: examPurple.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }

                ZStack(alignment: .leading) {
                    if viewModel.answerPreviewText.isEmpty {
                        Text("Введите ответ")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: "A1A8B7"))
                            .padding(.horizontal, 16)
                    } else {
                        ExamLatexAnswerWebView(
                            latex: viewModel.answerPreviewText,
                            keepsActiveFormulaOnOneLine: viewModel.keepsActiveFormulaOnOneLine,
                            height: $answerWebViewHeight
                        )
                        .frame(minHeight: max(answerWebViewHeight, 76))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                .padding(.vertical, 8)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(hex: "E1E5EF"), lineWidth: 1.2)
                }
                .shadow(color: examPurple.opacity(0.06), radius: 18, x: 0, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer(minLength: 8)

            ExamAnswerKeyboard(
                mode: viewModel.inputMode,
                containerWidth: UIScreen.main.bounds.width,
                onModeSelect: viewModel.selectInputMode,
                onDraft: { isDraftOpen = true },
                onInput: viewModel.appendKeyboardValue,
                onDelete: viewModel.deleteLastAnswerSymbol,
                onClear: viewModel.clearAnswer,
                onMoveCursorRight: viewModel.moveCursorRight
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            keyboardActionButtons
        }
        .background(.white)
        .onAppear {
            viewModel.prepareInputForCurrentMode()
        }
    }

    private var keyboardActionButtons: some View {
        HStack(spacing: 10) {
            Button {
                Task {
                    await viewModel.finishSession()
                    await onSubmitted()
                }
            } label: {
                bottomPillAction(title: "Завершить", tint: Color(hex: "22A95A"), background: Color(hex: "EAF8EF"))
            }
            .buttonStyle(.plain)

            Button {
                isExitConfirmationOpen = true
            } label: {
                bottomPillAction(title: "Выход", tint: Color(hex: "EF4444"), background: Color(hex: "FFF0F1"))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.continueFlow()
            } label: {
                bottomPillAction(title: "Продолжить", tint: .white, background: examPurple, isPrimary: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.white)
    }

    private func bottomPillAction(title: String, tint: Color, background: Color, isPrimary: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: isPrimary ? examPurple.opacity(0.20) : .black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private var examProgressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("№ \(viewModel.currentTaskNumber)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(examInk)

                Spacer()

                Text("\(answeredTasksCount)/\(max(viewModel.tasks.count, 1))")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(examPurple)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Color(hex: "F4F0FF"))
                    .clipShape(Capsule())
            }

            GeometryReader { proxy in
                let total = max(viewModel.tasks.count, 1)
                let progress = CGFloat(answeredTasksCount) / CGFloat(total)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "EEF1F7"))
                    if answeredTasksCount > 0 {
                        Capsule()
                            .fill(examPurple)
                            .frame(width: max(10, proxy.size.width * progress))
                    }
                }
            }
            .frame(height: 7)
        }
    }

    private var answeredTasksCount: Int {
        Set(viewModel.savedAnswers.keys).intersection(viewModel.tasks.map(\.id)).count
    }

    private var examPurple: Color { Color(hex: "7257F4") }
    private var examInk: Color { Color(hex: "20242D") }
}
