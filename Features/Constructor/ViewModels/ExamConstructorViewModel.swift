import Foundation

@MainActor
final class ExamConstructorViewModel: ObservableObject {
    @Published private(set) var title = "Конструктор"
    @Published private(set) var subjectTitle = ""
    @Published private(set) var datasetOptions: [ExamConstructorDatasetOption] = []
    @Published private(set) var selectedDatasetID: String
    @Published private(set) var options: [ExamConstructorQuestionOption] = []
    @Published private(set) var availableQuestionNumbers: [String] = []
    @Published private(set) var questionCount = 20
    @Published var durationSeconds = 2 * 60 * 60 + 30 * 60
    @Published var selectedSlotIndex = 0
    @Published var selectedQuestionNumber: String?
    @Published var selectedOptionID: ExamConstructorQuestionOption.ID?
    @Published private(set) var selectedOptionsBySlot: [Int: ExamConstructorQuestionOption] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let contentStore: EducationalContentStore

    init(datasetID: String, contentStore: EducationalContentStore) {
        self.selectedDatasetID = datasetID
        self.contentStore = contentStore
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

    var filteredOptions: [ExamConstructorQuestionOption] {
        guard let selectedQuestionNumber else { return options }
        return options.filter { $0.questionNumber == selectedQuestionNumber }
    }

    var selectedDatasetOption: ExamConstructorDatasetOption? {
        datasetOptions.first { $0.datasetID == selectedDatasetID }
    }

    var selectedQuestionOption: ExamConstructorQuestionOption? {
        options.first { $0.id == selectedOptionID }
    }

    var availableCategories: [ExamCategory] {
        [.ege, .oge, .vpr]
    }

    var addedCount: Int {
        selectedOptionsBySlot.count
    }

    var canStart: Bool {
        addedCount == questionCount
    }

    func load() async {
        if datasetOptions.isEmpty {
            datasetOptions = Self.buildDatasetOptions(initialDatasetID: selectedDatasetID)
        }
        await loadSelectedDataset(resetSelection: false)
    }

    func selectDataset(_ option: ExamConstructorDatasetOption) async {
        guard selectedDatasetID != option.datasetID else { return }
        selectedDatasetID = option.datasetID
        await loadSelectedDataset(resetSelection: true)
    }

    func datasetOptions(for category: ExamCategory) -> [ExamConstructorDatasetOption] {
        datasetOptions.filter { $0.category == category }
    }

    private func loadSelectedDataset(resetSelection: Bool) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let database = try await contentStore.loadDatabase(datasetID: selectedDatasetID) else {
                errorMessage = "База заданий пока не загружена"
                options = []
                availableQuestionNumbers = []
                selectedQuestionNumber = nil
                selectedOptionID = nil
                return
            }

            title = database.title
            subjectTitle = database.subject.title
            options = Self.buildOptions(from: database.tasks)
            availableQuestionNumbers = Array(Set(options.map(\.questionNumber))).sorted(by: Self.questionNumberSort)
            selectedQuestionNumber = availableQuestionNumbers.first
            selectedOptionID = filteredOptions.first?.id
            if resetSelection {
                selectedOptionsBySlot = [:]
                selectedSlotIndex = 0
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectSlot(_ index: Int) {
        guard index >= 0, index < questionCount else { return }
        selectedSlotIndex = index
        if let existing = selectedOptionsBySlot[index] {
            selectedQuestionNumber = existing.questionNumber
            selectedOptionID = existing.id
        }
    }

    func selectQuestionNumber(_ number: String) {
        selectedQuestionNumber = number
        selectedOptionID = filteredOptions.first?.id
    }

    func selectQuestionOption(_ option: ExamConstructorQuestionOption) {
        selectedQuestionNumber = option.questionNumber
        selectedOptionID = option.id
    }

    func addSelectedQuestion() {
        guard let selectedOption = filteredOptions.first(where: { $0.id == selectedOptionID }) else { return }
        selectedOptionsBySlot[selectedSlotIndex] = selectedOption

        if let nextEmptySlot = (0..<questionCount).first(where: { selectedOptionsBySlot[$0] == nil }) {
            selectSlot(nextEmptySlot)
        }
    }

    func removeQuestion(at slot: Int) {
        selectedOptionsBySlot[slot] = nil
        selectSlot(slot)
    }

    func increaseQuestionCount() {
        setQuestionCount(questionCount + 1)
    }

    func decreaseQuestionCount() {
        setQuestionCount(questionCount - 1)
    }

    func setQuestionCount(_ count: Int) {
        questionCount = min(max(count, 1), 50)
        normalizeSlots()
    }

    func setDuration(hours: Int, minutes: Int) {
        let normalizedHours = min(max(hours, 0), 5)
        let normalizedMinutes = min(max(minutes, 0), 55)
        let totalSeconds = normalizedHours * 3_600 + normalizedMinutes * 60
        durationSeconds = max(totalSeconds, 15 * 60)
    }

    func makeStartContext() -> ExamConstructorStartContext {
        let taskIDs = (0..<questionCount).compactMap { selectedOptionsBySlot[$0]?.taskID }
        return ExamConstructorStartContext(
            datasetID: selectedDatasetID,
            title: "Конструктор. \(subjectTitle.isEmpty ? title : subjectTitle)",
            taskIDs: taskIDs,
            durationSeconds: durationSeconds
        )
    }

    private func normalizeSlots() {
        if selectedSlotIndex >= questionCount {
            selectedSlotIndex = max(0, questionCount - 1)
        }
        selectedOptionsBySlot = selectedOptionsBySlot.filter { $0.key < questionCount }
    }

    private static func buildOptions(from tasks: [EducationalTask]) -> [ExamConstructorQuestionOption] {
        let grouped = Dictionary(grouping: tasks) { task in
            "\(task.questionNumber ?? "0")|\(task.topic)"
        }

        return grouped.values.compactMap { group in
            guard let task = group.sorted(by: { $0.id < $1.id }).first else { return nil }
            let questionNumber = task.questionNumber ?? "?"
            return ExamConstructorQuestionOption(
                id: "\(questionNumber)-\(task.topic)",
                taskID: task.id,
                questionNumber: questionNumber,
                topic: task.topic
            )
        }
        .sorted {
            if questionNumberSort($0.questionNumber, $1.questionNumber) {
                return true
            }
            if $0.questionNumber == $1.questionNumber {
                return $0.topic < $1.topic
            }
            return false
        }
    }

    private static func buildDatasetOptions(initialDatasetID: String) -> [ExamConstructorDatasetOption] {
        guard let program = HomeStudyProgram.all.first(where: { program in
            program.egeDatasetID == initialDatasetID ||
            program.ogeDatasetID == initialDatasetID ||
            program.egeVariants.contains(where: { $0.datasetID == initialDatasetID }) ||
            program.vprVariants.contains(where: { $0.datasetID == initialDatasetID })
        }) else {
            return [
                ExamConstructorDatasetOption(
                    id: initialDatasetID,
                    title: "ЕГЭ",
                    subtitle: "Доступная база",
                    category: .ege,
                    datasetID: initialDatasetID
                )
            ]
        }

        var options: [ExamConstructorDatasetOption] = []
        if program.egeVariants.isEmpty {
            if let egeDatasetID = program.egeDatasetID {
                options.append(
                    ExamConstructorDatasetOption(
                        id: egeDatasetID,
                        title: "ЕГЭ",
                        subtitle: program.title,
                        category: .ege,
                        datasetID: egeDatasetID
                    )
                )
            }
        } else {
            options.append(contentsOf: program.egeVariants.map { variant in
                ExamConstructorDatasetOption(
                    id: variant.datasetID,
                    title: variant.title,
                    subtitle: program.title,
                    category: .ege,
                    datasetID: variant.datasetID
                )
            })
        }

        if let ogeDatasetID = program.ogeDatasetID {
            options.append(
                ExamConstructorDatasetOption(
                    id: ogeDatasetID,
                    title: "ОГЭ",
                    subtitle: program.title,
                    category: .oge,
                    datasetID: ogeDatasetID
                )
            )
        }

        if program.vprVariants.isEmpty {
            return options
        }

        options.append(contentsOf: program.vprVariants.map { variant in
            ExamConstructorDatasetOption(
                id: variant.datasetID,
                title: "ВПР \(variant.title)",
                subtitle: program.title,
                category: .vpr,
                datasetID: variant.datasetID
            )
        })

        return options
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
}
