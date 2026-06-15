import Foundation

@MainActor
final class ExamWorkspaceViewModel: ObservableObject {
    @Published private(set) var title = "ЕГЭ"
    @Published private(set) var tasks: [EducationalTask] = []
    @Published var currentTaskIndex = 0
    @Published var selectedTab: ExamWorkspaceTab = .task
    @Published private(set) var answerText = ""
    @Published private(set) var remainingSeconds = 3_600
    @Published var savedAnswers: [EducationalTask.ID: String] = [:]
    @Published var inputMode: ExamAnswerInputMode = .russian
    @Published var showsRestoredSessionWarning = false
    @Published var showsTimeExpiredWarning = false
    @Published var resultReport: ExamResultReport?

    private let datasetID: String
    private let customTitle: String?
    private let customTaskIDs: [EducationalTask.ID]?
    private let customDurationSeconds: Int?
    private let proctoringConsent: ExamProctoringConsent?
    private let contentStore: EducationalContentStore
    private let examRepository: ExamRepository
    private let safeModeService: ExamSafeModeServicing?
    private var activeSession: ExamSession?
    private var timerTask: Task<Void, Never>?
    private var inputEngine = ExamLatexInputEngine()
    private var didMarkTimeExpired = false

    deinit {
        timerTask?.cancel()
        if let safeModeService {
            Task {
                await safeModeService.stop()
            }
        }
    }

    init(
        datasetID: String = SeedDatasetID.mathEGEBase.rawValue,
        customTitle: String? = nil,
        customTaskIDs: [EducationalTask.ID]? = nil,
        durationSeconds: Int? = nil,
        proctoringConsent: ExamProctoringConsent? = nil,
        contentStore: EducationalContentStore,
        examRepository: ExamRepository,
        safeModeService: ExamSafeModeServicing? = nil
    ) {
        self.datasetID = datasetID
        self.customTitle = customTitle
        self.customTaskIDs = customTaskIDs
        self.customDurationSeconds = durationSeconds
        self.proctoringConsent = proctoringConsent
        self.contentStore = contentStore
        self.examRepository = examRepository
        self.safeModeService = safeModeService
    }

    var currentTask: EducationalTask? {
        guard tasks.indices.contains(currentTaskIndex) else { return nil }
        return tasks[currentTaskIndex]
    }

    var currentTaskNumber: String {
        currentTask?.questionNumber ?? "\(currentTaskIndex + 1)"
    }

    func load() async {
        do {
            if let database = try await contentStore.loadDatabase(datasetID: datasetID) {
                title = customTitle ?? database.title
                let session = try await loadOrCreateSession(from: database)
                activeSession = session
                savedAnswers = session.answers
                tasks = tasksForSession(session, in: database)
                didMarkTimeExpired = session.timeExpiredAt != nil
                startTimer(for: session)
                startSafeModeIfNeeded(for: session)
                restoreAnswerForCurrentTask()
                return
            }
        } catch {
            #if DEBUG
            print("[ExamWorkspace][Session] failed dataset=\(datasetID): \(error.localizedDescription)")
            #endif
        }

        tasks = Self.fallbackTasks
        restoreAnswerForCurrentTask()
    }

    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func selectTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        saveCurrentAnswer()
        currentTaskIndex = index
        selectedTab = .task
        restoreAnswerForCurrentTask()
    }

    var answerPreviewText: String {
        inputEngine.latexForRendering
    }

    var answerStorageText: String {
        inputEngine.latexForSaving
    }

    var keepsActiveFormulaOnOneLine: Bool {
        inputEngine.keepsActiveFormulaOnOneLine
    }

    func selectInputMode(_ mode: ExamAnswerInputMode) {
        guard inputMode != mode else {
            prepareInputForCurrentMode()
            return
        }

        inputMode = mode
        prepareInputForCurrentMode()
    }

    func prepareInputForCurrentMode() {
        switch inputMode {
        case .math:
            inputEngine.closeTextIfNeeded()
        case .russian, .english:
            inputEngine.openTextIfNeeded()
        }
        syncAnswerText()
    }

    func appendKeyboardValue(_ value: String) {
        if value == "\n" {
            inputEngine.insertLineBreak()
            syncAnswerText()
            return
        }

        switch inputMode {
        case .math:
            inputEngine.insertMathSymbol(value)
        case .russian, .english:
            inputEngine.insertText(value)
        }
        syncAnswerText()
    }

    func deleteLastAnswerSymbol() {
        inputEngine.delete()
        syncAnswerText()
    }

    func clearAnswer() {
        inputEngine.clear()
        syncAnswerText()
        prepareInputForCurrentMode()
    }

    func saveCurrentAnswer() {
        guard let currentTask else { return }
        let answerToSave = preparedAnswerForSaving()
        updateLocalAnswer(answerToSave, taskID: currentTask.id)

        guard let activeSession else { return }
        Task {
            do {
                try await examRepository.saveAnswer(answerToSave, taskID: currentTask.id, sessionID: activeSession.id)
            } catch {
                #if DEBUG
                print("[ExamWorkspace][Session] failed to save answer session=\(activeSession.id) task=\(currentTask.id): \(error.localizedDescription)")
                #endif
            }
        }
    }

    func goToNextTask() {
        saveCurrentAnswer()
        guard currentTaskIndex + 1 < tasks.count else { return }
        currentTaskIndex += 1
        selectedTab = .task
        restoreAnswerForCurrentTask()
    }

    func continueFlow() {
        saveCurrentAnswer()

        if selectedTab == .task {
            selectedTab = .answer
            prepareInputForCurrentMode()
            return
        }

        goToNextTask()
    }

    func saveAndInterruptSession() async {
        await saveCurrentAnswerAwaiting()
        guard let activeSession else { return }

        do {
            await safeModeService?.stop()
            try await examRepository.updateSessionStatus(.interrupted, sessionID: activeSession.id)
            #if DEBUG
            print("[ExamWorkspace][Session] interrupted session=\(activeSession.id) dataset=\(datasetID)")
            #endif
        } catch {
            #if DEBUG
            print("[ExamWorkspace][Session] failed to interrupt session=\(activeSession.id): \(error.localizedDescription)")
            #endif
        }
    }

    func finishSession(invalidateSafeSession: Bool = false) async {
        await saveCurrentAnswerAwaiting()
        guard let activeSession else { return }

        do {
            // Stop SafeMode and run post-exam analysis
            let safeModeReport = await safeModeService?.stopAndReport()
            if activeSession.safeModeEnabled,
               (safeModeReport?.totalCaptureCount ?? 0) == 0 {
                try await examRepository.markSafeSessionInvalid(sessionID: activeSession.id)
            }

            if invalidateSafeSession {
                try await examRepository.markSafeSessionInvalid(sessionID: activeSession.id)
            }
            try await examRepository.updateSessionStatus(.submitted, sessionID: activeSession.id)
            let submittedSession = try await examRepository.session(id: activeSession.id) ?? activeSession
            self.activeSession = submittedSession
            resultReport = makeResultReport(from: submittedSession, safeModeReport: safeModeReport)
            #if DEBUG
            print("[ExamWorkspace][Session] submitted session=\(activeSession.id) dataset=\(datasetID) safeModeScore=\(safeModeReport?.score.description ?? "n/a")")
            #endif
        } catch {
            #if DEBUG
            print("[ExamWorkspace][Session] failed to submit session=\(activeSession.id): \(error.localizedDescription)")
            #endif
        }
    }

    private func saveCurrentAnswerAwaiting() async {
        guard let currentTask else { return }
        let answerToSave = preparedAnswerForSaving()
        updateLocalAnswer(answerToSave, taskID: currentTask.id)

        guard var activeSession else { return }
        do {
            try await examRepository.saveAnswer(answerToSave, taskID: currentTask.id, sessionID: activeSession.id)
            activeSession.answers = savedAnswers
            self.activeSession = activeSession
        } catch {
            #if DEBUG
            print("[ExamWorkspace][Session] failed to save answer session=\(activeSession.id) task=\(currentTask.id): \(error.localizedDescription)")
            #endif
        }
    }

    private func preparedAnswerForSaving() -> String? {
        let cleaned = answerStorageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty || cleaned == "\\text{}" {
            return nil
        }
        return cleaned
    }

    private func updateLocalAnswer(_ answer: String?, taskID: EducationalTask.ID) {
        if let answer {
            savedAnswers[taskID] = answer
        } else {
            savedAnswers[taskID] = nil
        }
    }

    private func makeResultReport(from session: ExamSession, safeModeReport: ExamSafeModeReport? = nil) -> ExamResultReport {
        let tasksByID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let orderedTasks = session.taskIDs.compactMap { tasksByID[$0] }
        let reportTasks = orderedTasks.isEmpty ? tasks : orderedTasks
        let items = reportTasks.enumerated().map { index, task in
            ExamResultReportItem(
                id: task.id,
                subjectID: task.subjectID,
                number: task.questionNumber ?? "\(index + 1)",
                topic: task.topic,
                questionHTML: task.questionHTML,
                drawingURL: task.drawingURL,
                audioURL: task.audioURL,
                userAnswer: session.answers[task.id],
                correctAnswer: task.answer,
                answerDrawingURL: task.answerDrawingURL,
                explanationHTML: task.explanationHTML,
                explanationDrawingURL: task.explanationDrawingURL
            )
        }

        return ExamResultReport(
            id: session.id,
            title: title,
            subjectTitle: session.subjectTitle.isEmpty ? title : session.subjectTitle,
            kindTitle: session.kind.title,
            completedAt: session.submittedAt ?? Date(),
            durationSeconds: session.actualDurationSeconds ?? Int(Date().timeIntervalSince(session.startedAt)),
            safeSessionValid: session.safeSessionValid,
            safeModeReport: safeModeReport,
            items: items
        )
    }

    private func restoreAnswerForCurrentTask() {
        guard let currentTask else {
            inputEngine.clear()
            syncAnswerText()
            return
        }
        inputEngine.restore(savedAnswers[currentTask.id] ?? "")
        syncAnswerText()
        inputMode = .russian
    }

    func moveCursorRight() {
        inputEngine.moveCursorRight()
        syncAnswerText()
    }

    private func syncAnswerText() {
        answerText = answerPreviewText
    }

    private func startTimer(for session: ExamSession) {
        timerTask?.cancel()
        remainingSeconds = Self.remainingSeconds(for: session)
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    self.remainingSeconds = max(0, self.remainingSeconds - 1)
                    if self.remainingSeconds == 0 {
                        self.handleTimerExpired()
                    }
                }
            }
        }
    }

    private static func remainingSeconds(for session: ExamSession) -> Int {
        let elapsed = Int(Date().timeIntervalSince(session.startedAt))
        return max(0, session.durationSeconds - elapsed)
    }

    private func handleTimerExpired() {
        guard !didMarkTimeExpired, let activeSession else { return }
        didMarkTimeExpired = true
        showsTimeExpiredWarning = true
        Task {
            try? await examRepository.markTimeExpired(sessionID: activeSession.id)
        }
    }

    private func startSafeModeIfNeeded(for session: ExamSession) {
        guard session.safeModeEnabled,
              session.safeSessionValid,
              session.proctoringConsent?.allowsCamera == true,
              safeModeService != nil else {
            return
        }

        Task {
            let started = await safeModeService?.start(
                configuration: ExamSafeModeConfiguration(
                    sessionID: session.id,
                    durationSeconds: session.durationSeconds,
                    maxCaptures: 20,
                    recordsCamera: session.proctoringConsent?.allowsCamera == true,
                    recordsMicrophone: session.proctoringConsent?.allowsMicrophone == true
                )
            ) ?? false
            if !started {
                try? await examRepository.markSafeSessionInvalid(sessionID: session.id)
                if var current = self.activeSession, current.id == session.id {
                    current.safeSessionValid = false
                    self.activeSession = current
                }
            }
        }
    }

    private func loadOrCreateSession(from database: EducationalContentDatabase) async throws -> ExamSession {
        if let session = try await examRepository.activeSession(datasetID: datasetID) {
            try await examRepository.markSafeSessionInvalid(sessionID: session.id)
            showsRestoredSessionWarning = true
            if let proctoringConsent, session.proctoringConsent == nil {
                try await examRepository.updateProctoringConsent(proctoringConsent, sessionID: session.id)
            }
            #if DEBUG
            print("[ExamWorkspace][Session] restored dataset=\(datasetID) session=\(session.id) tasks=\(session.taskIDs.count) answers=\(session.answers.count) proctoring=\(session.proctoringConsent != nil)")
            #endif
            if let proctoringConsent, session.proctoringConsent == nil {
                var updatedSession = session
                updatedSession.proctoringConsent = proctoringConsent
                updatedSession.safeSessionValid = false
                return updatedSession
            }
            var restoredSession = session
            restoredSession.safeSessionValid = false
            return restoredSession
        }

        let selectedTasks = selectedTasks(from: database)
        let selectedTaskIDs = selectedTasks.map(\.id)

        let session = try await examRepository.startSession(
            datasetID: datasetID,
            title: customTitle ?? database.title,
            subjectID: database.subject.id,
            subjectTitle: database.subject.title,
            kind: customTaskIDs == nil ? Self.kind(for: database.examCategory) : .constructor,
            taskIDs: selectedTaskIDs,
            durationSeconds: ExamDurationPolicy.durationSeconds(
                datasetID: datasetID,
                subjectID: database.subject.id,
                kind: customTaskIDs == nil ? Self.kind(for: database.examCategory) : .constructor,
                customDurationSeconds: customDurationSeconds
            ),
            proctoringConsent: proctoringConsent
        )
        #if DEBUG
        print("[ExamWorkspace][Session] created dataset=\(datasetID) session=\(session.id) tasks=\(session.taskIDs.count) proctoring=\(session.proctoringConsent != nil)")
        #endif
        return session
    }

    private static func kind(for category: ExamCategory) -> ExamSessionKind {
        switch category {
        case .ege: return .ege
        case .oge: return .oge
        case .vpr: return .vpr
        case .constructor: return .constructor
        }
    }

    private func tasksForSession(_ session: ExamSession, in database: EducationalContentDatabase) -> [EducationalTask] {
        let tasksByID = Dictionary(uniqueKeysWithValues: database.tasks.map { ($0.id, $0) })
        let sessionTasks = session.taskIDs.compactMap { tasksByID[$0] }
        return sessionTasks.isEmpty ? selectedTasks(from: database) : sessionTasks
    }

    private func selectedTasks(from database: EducationalContentDatabase) -> [EducationalTask] {
        if let customTaskIDs, !customTaskIDs.isEmpty {
            let tasksByID = Dictionary(uniqueKeysWithValues: database.tasks.map { ($0.id, $0) })
            let tasks = customTaskIDs.compactMap { tasksByID[$0] }
            if !tasks.isEmpty {
                return tasks
            }
        }

        return Self.selectExamTasks(from: database.tasks, datasetID: datasetID)
    }

    private static func selectExamTasks(from tasks: [EducationalTask], datasetID: String) -> [EducationalTask] {
        let limit = questionLimit(for: datasetID)
        let groupedByQuestionNumber = Dictionary(grouping: tasks) { task in
            task.questionNumber ?? task.id
        }

        let selectedByNumber = groupedByQuestionNumber
            .keys
            .sorted(by: questionNumberSort)
            .compactMap { number in
                groupedByQuestionNumber[number]?.randomElement()
            }

        let selectedTasks = selectedByNumber.prefix(limit)
        if selectedTasks.count == limit {
            return Array(selectedTasks)
        }

        let selectedIDs = Set(selectedTasks.map(\.id))
        let filler = tasks
            .filter { !selectedIDs.contains($0.id) }
            .shuffled()
            .prefix(max(0, limit - selectedTasks.count))
        return Array(selectedTasks) + Array(filler)
    }

    private static func questionLimit(for datasetID: String) -> Int {
        switch datasetID {
        case SeedDatasetID.mathEGEBase.rawValue:
            return 21
        case SeedDatasetID.mathEGEProfile.rawValue:
            return 19
        case SeedDatasetID.mathOGE.rawValue:
            return 25
        case SeedDatasetID.mathVPR6.rawValue:
            return 16
        case SeedDatasetID.mathVPR7.rawValue:
            return 17
        case SeedDatasetID.mathVPR7Advanced.rawValue:
            return 16
        case SeedDatasetID.mathVPR8.rawValue:
            return 18
        case SeedDatasetID.mathVPR8Advanced.rawValue:
            return 16
        case SeedDatasetID.russianEGE.rawValue:
            return 27
        case SeedDatasetID.russianOGE.rawValue:
            return 13
        case SeedDatasetID.russianVPR6.rawValue:
            return 5
        case SeedDatasetID.russianVPR7.rawValue:
            return 7
        case SeedDatasetID.russianVPR.rawValue:
            return 10
        case SeedDatasetID.historyEGE.rawValue:
            return 21
        case SeedDatasetID.historyOGE.rawValue:
            return 24
        case SeedDatasetID.historyVPR6.rawValue:
            return 11
        case SeedDatasetID.historyVPR7.rawValue:
            return 10
        case SeedDatasetID.historyVPR8.rawValue:
            return 11
        case SeedDatasetID.englishEGE.rawValue:
            return 42
        case SeedDatasetID.englishOGE.rawValue:
            return 38
        case SeedDatasetID.englishVPR6.rawValue,
             SeedDatasetID.englishVPR7.rawValue,
             SeedDatasetID.englishVPR8.rawValue:
            return 4
        default:
            return 25
        }
    }

    private static func questionNumberSort(_ lhs: String, _ rhs: String) -> Bool {
        let lhsNumber = Int(lhs)
        let rhsNumber = Int(rhs)
        switch (lhsNumber, rhsNumber) {
        case let (lhs?, rhs?):
            return lhs < rhs
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs < rhs
        }
    }

    private static func taskSort(_ lhs: EducationalTask, _ rhs: EducationalTask) -> Bool {
        if questionNumberSort(lhs.questionNumber ?? "", rhs.questionNumber ?? "") {
            return true
        }
        if lhs.questionNumber == rhs.questionNumber {
            return lhs.id < rhs.id
        }
        return false
    }

    private static let fallbackTasks = [
        EducationalTask(
            id: "ege-draft-placeholder",
            questionNumber: "1",
            topic: "ЕГЭ",
            questionHTML: "<p>Задание загружается из локальной базы. Пока можно проверить рабочее место экзамена: WebView, ответ, клавиатуру и черновик.</p>",
            drawingURL: nil,
            explanationDrawingURL: nil,
            answerDrawingURL: nil,
            audioURL: nil,
            answerType: "краткий ответ",
            answer: "",
            difficulty: nil,
            resourceID: nil,
            explanationHTML: nil,
            subjectID: "math",
            examCategory: .ege,
            level: "base",
            blockID: "fallback"
        )
    ]
}

enum ExamWorkspaceTab: String, CaseIterable {
    case task = "Задание"
    case answer = "Ответ"
}

enum ExamAnswerInputMode: String, CaseIterable, Identifiable {
    case russian
    case english
    case math

    var id: String { rawValue }

    var title: String {
        switch self {
        case .russian:
            return "RU"
        case .english:
            return "EN"
        case .math:
            return "∑"
        }
    }
}
