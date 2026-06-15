import Foundation

@MainActor
final class TeacherAssignmentConstructorViewModel: ObservableObject {
    static let customQuestionDatasetID = "teacher-custom-question"

    @Published private(set) var datasetOptions: [ExamConstructorDatasetOption] = []
    @Published private(set) var selectedDatasetID: String?
    @Published private(set) var currentTasks: [EducationalTask] = []
    @Published private(set) var questionGroups: [TeacherAssignmentQuestionGroup] = []
    @Published private(set) var selectedGroupID: String?
    @Published private(set) var selectedGroupTaskIndex = 0
    @Published private(set) var selectedSeedItems: [TeacherAssignmentSeedItem] = []
    @Published var selectedSlotIndex = 0
    @Published var customDraft = TeacherCustomAssignmentDraft()
    @Published private(set) var customDrafts: [TeacherCustomAssignmentDraft] = []
    @Published var publishDraft = TeacherAssignmentPublishDraft(
        title: "Домашнее задание",
        studentIDsText: ""
    )
    @Published private(set) var isLoading = false
    @Published private(set) var isPublishing = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableStudents: [TeacherLocalStudent] = []

    private let summary: TeacherHomeSummary
    private let contentStore: EducationalContentStore
    private let seedDataBootstrapService: SeedDataBootstrapServicing
    private let repository: TeacherAssignmentRepository
    private let studentsRepository: TeacherStudentsRepository

    init(
        summary: TeacherHomeSummary,
        contentStore: EducationalContentStore,
        seedDataBootstrapService: SeedDataBootstrapServicing,
        repository: TeacherAssignmentRepository,
        studentsRepository: TeacherStudentsRepository
    ) {
        self.summary = summary
        self.contentStore = contentStore
        self.seedDataBootstrapService = seedDataBootstrapService
        self.repository = repository
        self.studentsRepository = studentsRepository
    }

    var isCustomQuestionMode: Bool {
        selectedDatasetID == Self.customQuestionDatasetID
    }

    var selectedDatasetOption: ExamConstructorDatasetOption? {
        guard let selectedDatasetID else { return nil }
        return datasetOptions.first { $0.datasetID == selectedDatasetID }
    }

    var selectedQuestionGroup: TeacherAssignmentQuestionGroup? {
        guard let selectedGroupID else { return nil }
        return questionGroups.first { $0.id == selectedGroupID }
    }

    var currentTask: EducationalTask? {
        guard let selectedQuestionGroup,
              selectedQuestionGroup.tasks.indices.contains(selectedGroupTaskIndex) else {
            return nil
        }
        return selectedQuestionGroup.tasks[selectedGroupTaskIndex]
    }

    var selectedCount: Int {
        selectedSeedItems.count + customDrafts.count
    }

    var questionCount: Int {
        publishDraft.questionCount
    }

    var durationSeconds: Int {
        publishDraft.durationSeconds
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3_600
        let minutes = (durationSeconds % 3_600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    var durationHours: Int {
        durationSeconds / 3_600
    }

    var durationMinutes: Int {
        (durationSeconds % 3_600) / 60
    }

    var canAddCustomDraft: Bool {
        customDraft.isValid && selectedCount < questionCount
    }

    var canPublish: Bool {
        !publishDraft.trimmedTitle.isEmpty &&
            !publishDraft.studentIDs.isEmpty &&
            selectedCount > 0 &&
            selectedCount <= questionCount &&
            publishDraft.dueAt > Date() &&
            !isPublishing
    }

    func load() async {
        guard datasetOptions.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        availableStudents = (try? await studentsRepository.loadStudents()) ?? []
        datasetOptions = Self.buildDatasetOptions(subjectTitle: summary.subjectTitle)
        selectedDatasetID = datasetOptions.first?.datasetID
        await loadSelectedDataset()
    }

    func selectDataset(_ option: ExamConstructorDatasetOption) async {
        guard selectedDatasetID != option.datasetID else { return }
        selectedDatasetID = option.datasetID
        resetSelection()
        await loadSelectedDataset()
    }

    func selectQuestionGroup(_ group: TeacherAssignmentQuestionGroup) {
        guard selectedGroupID != group.id else { return }
        selectedGroupID = group.id
        selectedGroupTaskIndex = 0
    }

    func showPreviousTaskInGroup() {
        guard selectedQuestionGroup != nil else { return }
        selectedGroupTaskIndex = max(0, selectedGroupTaskIndex - 1)
    }

    func showNextTaskInGroup() {
        guard let selectedQuestionGroup else { return }
        selectedGroupTaskIndex = min(selectedQuestionGroup.tasks.count - 1, selectedGroupTaskIndex + 1)
    }

    func addCurrentSeedTask() {
        guard let selectedDatasetID, let currentTask else { return }
        guard selectedCount < questionCount else { return }
        let itemID = "\(selectedDatasetID)-\(currentTask.id)"
        guard !selectedSeedItems.contains(where: { $0.id == itemID }) else { return }
        selectedSeedItems.append(
            TeacherAssignmentSeedItem(
                id: itemID,
                datasetID: selectedDatasetID,
                task: currentTask
            )
        )
        selectNextOpenSlot()
    }

    func removeSeedItem(id: String) {
        selectedSeedItems.removeAll { $0.id == id }
    }

    func addCustomDraft() {
        guard customDraft.isValid else { return }
        guard selectedCount < questionCount else { return }
        customDrafts.append(customDraft)
        customDraft = TeacherCustomAssignmentDraft()
        selectNextOpenSlot()
    }

    func removeCustomDraft(at offsets: IndexSet) {
        customDrafts.remove(atOffsets: offsets)
    }

    func setCustomAttachment(data: Data, filename: String, contentType: String, originalBytes: Int) {
        customDraft.attachment = TeacherAssignmentAttachmentDraft(
            data: data,
            filename: filename,
            contentType: contentType,
            originalBytes: originalBytes
        )
    }

    func setCustomAttachmentError(_ message: String) {
        errorMessage = message
    }

    func selectSlot(_ index: Int) {
        guard index >= 0, index < questionCount else { return }
        selectedSlotIndex = index
    }

    func increaseQuestionCount() {
        setQuestionCount(questionCount + 1)
    }

    func decreaseQuestionCount() {
        setQuestionCount(questionCount - 1)
    }

    func setQuestionCount(_ count: Int) {
        publishDraft.questionCount = min(max(count, 1), 50)
        if selectedSlotIndex >= questionCount {
            selectedSlotIndex = max(0, questionCount - 1)
        }
    }

    func setDuration(hours: Int, minutes: Int) {
        let normalizedHours = min(max(hours, 0), 5)
        let normalizedMinutes = min(max(minutes, 0), 55)
        let totalSeconds = normalizedHours * 3_600 + normalizedMinutes * 60
        publishDraft.durationSeconds = max(totalSeconds, 15 * 60)
    }

    func setSelectedStudentID(_ studentID: String?) {
        publishDraft.studentIDsText = studentID ?? ""
    }

    var selectedStudentDisplayTitle: String {
        guard let selectedID = publishDraft.studentIDs.first else {
            return "Выберите ученика"
        }
        guard let student = availableStudents.first(where: { $0.id == selectedID }) else {
            return selectedID
        }
        return "\(student.displayName) · ID \(student.publicID)"
    }

    func publish() async {
        guard canPublish else { return }
        isPublishing = true
        errorMessage = nil
        statusMessage = nil
        defer { isPublishing = false }

        do {
            let payload = try await repository.publishAssignment(
                title: publishDraft.trimmedTitle,
                studentIDs: publishDraft.studentIDs,
                durationSeconds: publishDraft.durationSeconds,
                questionCount: publishDraft.questionCount,
                dueAt: publishDraft.dueAt,
                seedItems: selectedSeedItems,
                customDrafts: customDrafts
            )
            statusMessage = "Назначение создано: \(payload.title)"
            selectedSeedItems = []
            customDrafts = []
            publishDraft.studentIDsText = ""
            selectedSlotIndex = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadSelectedDataset() async {
        guard let selectedDatasetID else {
            currentTasks = []
            questionGroups = []
            return
        }

        if selectedDatasetID == Self.customQuestionDatasetID {
            currentTasks = []
            questionGroups = []
            resetSelection()
            errorMessage = nil
            return
        }

        do {
            guard let database = try await contentStore.loadDatabase(datasetID: selectedDatasetID) else {
                currentTasks = []
                questionGroups = []
                errorMessage = "База заданий пока не загружена"
                return
            }
            currentTasks = database.tasks.sorted(by: Self.taskSort)
            questionGroups = Self.buildQuestionGroups(from: currentTasks)
            selectedGroupID = questionGroups.first?.id
            selectedGroupTaskIndex = 0
        } catch {
            currentTasks = []
            questionGroups = []
            errorMessage = error.localizedDescription
        }
    }

    private static func buildDatasetOptions(subjectTitle: String) -> [ExamConstructorDatasetOption] {
        let normalizedTitle = subjectTitle
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSubject = normalizedSubjectID(from: subjectTitle)
        let hasSelectedSubject = !normalizedTitle.isEmpty && normalizedTitle != "предмет не выбран"
        let datasets = SeedDatasetCatalog.all.filter { dataset in
            guard hasSelectedSubject else { return true }
            if let normalizedSubject {
                return dataset.subject.id == normalizedSubject
            }
            let datasetTitle = dataset.subject.title.lowercased()
            return datasetTitle.contains(normalizedTitle) || normalizedTitle.contains(datasetTitle)
        }

        var options = datasets.map { dataset in
            ExamConstructorDatasetOption(
                id: dataset.id.rawValue,
                title: dataset.title,
                subtitle: dataset.examCategory.rawValue,
                category: dataset.examCategory,
                datasetID: dataset.id.rawValue
            )
        }

        options.append(
            ExamConstructorDatasetOption(
                id: Self.customQuestionDatasetID,
                title: "Свой вопрос",
                subtitle: "Заполнить вручную",
                category: .constructor,
                datasetID: Self.customQuestionDatasetID
            )
        )

        return options
    }

    private static func normalizedSubjectID(from subjectTitle: String) -> String? {
        let normalized = subjectTitle
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.isEmpty || normalized == "предмет не выбран" {
            return nil
        }
        if normalized.contains("мат") || normalized == "math" {
            return "math"
        }
        if normalized.contains("рус") || normalized == "russian" {
            return "russian"
        }
        if normalized.contains("ист") || normalized == "history" {
            return "history"
        }
        return nil
    }

    private static func taskSort(_ lhs: EducationalTask, _ rhs: EducationalTask) -> Bool {
        let lhsNumber = Int(lhs.questionNumber ?? "")
        let rhsNumber = Int(rhs.questionNumber ?? "")
        switch (lhsNumber, rhsNumber) {
        case let (lhs?, rhs?) where lhs != rhs:
            return lhs < rhs
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            return lhs.id < rhs.id
        }
    }

    private static func buildQuestionGroups(from tasks: [EducationalTask]) -> [TeacherAssignmentQuestionGroup] {
        let groupedTasks = Dictionary(grouping: tasks) { task in
            let questionNumber = task.questionNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedQuestionNumber = questionNumber?.isEmpty == false ? questionNumber! : "?"
            return "\(normalizedQuestionNumber)|\(task.topic)"
        }

        return groupedTasks.map { key, tasks in
            let sortedTasks = tasks.sorted(by: taskSort)
            let representative = sortedTasks[0]
            let questionNumber = representative.questionNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedQuestionNumber = questionNumber?.isEmpty == false ? questionNumber! : "?"
            return TeacherAssignmentQuestionGroup(
                id: key,
                questionNumber: normalizedQuestionNumber,
                topic: representative.topic,
                tasks: sortedTasks
            )
        }
        .sorted { lhs, rhs in
            let lhsNumber = Int(lhs.questionNumber)
            let rhsNumber = Int(rhs.questionNumber)
            switch (lhsNumber, rhsNumber) {
            case let (lhs?, rhs?) where lhs != rhs:
                return lhs < rhs
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                return lhs.topic < rhs.topic
            }
        }
    }

    private func resetSelection() {
        selectedGroupID = nil
        selectedGroupTaskIndex = 0
    }

    private func selectNextOpenSlot() {
        selectedSlotIndex = min(selectedCount, max(0, questionCount - 1))
    }
}
