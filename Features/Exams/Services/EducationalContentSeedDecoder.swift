import Foundation

protocol EducationalContentSeedDecoding {
    func decode(from url: URL, dataset: SeedDataset) throws -> EducationalContentDatabase
}

final class EducationalContentSeedDecoder: EducationalContentSeedDecoding {
    private let decoder: JSONDecoder
    private var exportsByPath: [String: ExamUpSeedExport] = [:]

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func decode(from url: URL, dataset: SeedDataset) throws -> EducationalContentDatabase {
        let path = url.path
        let export: ExamUpSeedExport
        if let cachedExport = exportsByPath[path] {
            export = cachedExport
            #if DEBUG
            print("[SeedData][Decoder] cache hit file=\(url.lastPathComponent) dataset=\(dataset.id.rawValue)")
            #endif
        } else {
            let start = Date()
            let data = try Data(contentsOf: url)
            export = try decoder.decode(ExamUpSeedExport.self, from: data)
            exportsByPath[path] = export
            #if DEBUG
            let elapsed = Date().timeIntervalSince(start)
            print("[SeedData][Decoder] decoded file=\(url.lastPathComponent) bytes=\(data.count) questions=\(export.tasks.count) elapsed=\(String(format: "%.2f", elapsed))s")
            #endif
        }
        return export.toDatabase(defaults: dataset)
    }
}

private struct ExamUpSeedExport: Decodable {
    let metadata: ExamUpSeedMetadata?
    let datasetID: String?
    let title: String?
    let subjectID: String?
    let subjectTitle: String?
    let examCategory: ExamCategory?
    let level: String?
    let version: Int?
    let source: String?
    let drawings: [ExamUpSeedDrawing]
    let questionDrawings: [ExamUpSeedQuestionDrawing]
    let tasks: [ExamUpSeedTask]

    enum CodingKeys: String, CodingKey {
        case metadata
        case datasetID = "dataset_id"
        case title
        case subjectID = "subject_id"
        case subjectTitle = "subject_title"
        case examCategory = "exam_category"
        case level
        case version
        case source
        case drawings
        case questionDrawings = "question_drawings"
        case tasks
        case questions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        metadata = try container.decodeIfPresent(ExamUpSeedMetadata.self, forKey: .metadata)
        datasetID = try container.decodeIfPresent(String.self, forKey: .datasetID)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        subjectID = try container.decodeIfPresent(String.self, forKey: .subjectID)
        subjectTitle = try container.decodeIfPresent(String.self, forKey: .subjectTitle)
        examCategory = try container.decodeIfPresent(ExamCategory.self, forKey: .examCategory)
        level = try container.decodeIfPresent(String.self, forKey: .level)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        drawings = try container.decodeIfPresent([ExamUpSeedDrawing].self, forKey: .drawings) ?? []
        questionDrawings = try container.decodeIfPresent([ExamUpSeedQuestionDrawing].self, forKey: .questionDrawings) ?? []
        tasks = try container.decodeIfPresent([ExamUpSeedTask].self, forKey: .tasks)
            ?? container.decodeIfPresent([ExamUpSeedTask].self, forKey: .questions)
            ?? []
    }

    func toDatabase(defaults dataset: SeedDataset) -> EducationalContentDatabase {
        let resolvedDatasetID = datasetID ?? dataset.id.rawValue
        let resolvedSubject = Subject(
            id: subjectID ?? dataset.subject.id,
            title: subjectTitle ?? metadata?.subject ?? dataset.subject.title
        )
        let resolvedExamCategory = examCategory ?? dataset.examCategory
        let resolvedVersion = version ?? dataset.initialVersion
        let resolvedTasks = tasks.filter { $0.matches(dataset: dataset) }
        let drawingCodeByID = Dictionary(uniqueKeysWithValues: drawings.map { ($0.id, $0.code) })
        let drawingRefsByQuestionID = Dictionary(
            grouping: questionDrawings.sorted { $0.position < $1.position },
            by: \.questionID
        )
        let groupedTasks = Dictionary(grouping: resolvedTasks) { $0.topic.trimmedOrFallback("Общий блок") }

        let blocks = groupedTasks
            .keys
            .sorted()
            .map { topic -> EducationalContentBlock in
                let blockID = Self.stableID(prefix: resolvedDatasetID, value: topic)
                return EducationalContentBlock(
                    id: blockID,
                    title: topic,
                    subjectID: resolvedSubject.id,
                    examCategory: resolvedExamCategory,
                    taskIDs: groupedTasks[topic, default: []].map(\.id)
                )
            }

        let blockIDsByTopic = Dictionary(uniqueKeysWithValues: blocks.map { ($0.title, $0.id) })
        let domainTasks = resolvedTasks.map { task in
            task.toDomainTask(
                subjectID: resolvedSubject.id,
                examCategory: resolvedExamCategory,
                level: level ?? dataset.level,
                blockID: blockIDsByTopic[task.topic.trimmedOrFallback("Общий блок")] ?? resolvedDatasetID,
                drawingCodeByID: drawingCodeByID,
                drawingRefsByQuestionID: drawingRefsByQuestionID
            )
        }

        return EducationalContentDatabase(
            datasetID: resolvedDatasetID,
            title: title ?? dataset.title,
            subject: resolvedSubject,
            examCategory: resolvedExamCategory,
            level: level ?? dataset.level,
            version: resolvedVersion,
            source: source ?? metadata?.sourceFile,
            blocks: blocks,
            tasks: domainTasks
        )
    }

    private static func stableID(prefix: String, value: String) -> String {
        let slug = value
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return "\(prefix)-\(slug.isEmpty ? "block" : slug)"
    }
}

private struct ExamUpSeedMetadata: Decodable {
    let subject: String?
    let sourceFile: String?

    enum CodingKeys: String, CodingKey {
        case subject
        case sourceFile = "source_file"
    }
}

private struct ExamUpSeedDrawing: Decodable {
    let id: String
    let code: String
}

private struct ExamUpSeedQuestionDrawing: Decodable {
    let questionID: String
    let drawingID: String
    let context: String
    let position: Int

    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case drawingID = "drawing_id"
        case context
        case position
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionID = try container.decode(String.self, forKey: .questionID)
        drawingID = try container.decode(String.self, forKey: .drawingID)
        context = try container.decodeIfPresent(String.self, forKey: .context) ?? "task"
        position = try container.decodeIfPresent(Int.self, forKey: .position) ?? 0
    }
}

private struct ExamUpSeedTask: Decodable {
    let id: String
    let questionNumber: String?
    let topic: String
    let questionHTML: String
    let drawingURL: String?
    let audioURL: String?
    let answerType: String?
    let answer: String
    let difficulty: String?
    let resourceID: String?
    let explanationHTML: String?
    let taskEmbeddedImageCount: Int
    let explanationEmbeddedImageCount: Int
    let subject: String?
    let exam: String?

    enum CodingKeys: String, CodingKey {
        case id
        case questionNumber = "question_number"
        case topic
        case questionHTML = "question_html"
        case taskHTML = "task_html"
        case drawingURL = "drawing_url"
        case drawing
        case audioURL = "audio_url"
        case audioPath = "audio_path"
        case audio
        case answerType = "answer_type"
        case answer
        case difficulty
        case resourceID = "resource_id"
        case resource
        case explanationHTML = "explanation_html"
        case subject
        case exam
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        questionNumber = try container.decodeFlexibleStringIfPresent(forKey: .questionNumber)
        topic = try container.decodeIfPresent(String.self, forKey: .topic) ?? "Общий блок"
        let rawQuestionHTML = try container.decodeIfPresent(String.self, forKey: .questionHTML)
            ?? container.decodeIfPresent(String.self, forKey: .taskHTML)
            ?? ""
        taskEmbeddedImageCount = rawQuestionHTML.embeddedImageCount
        let rawDrawing = try container.decodeFlexibleStringIfPresent(forKey: .drawingURL)
            ?? container.decodeFlexibleStringIfPresent(forKey: .drawing)
        drawingURL = rawDrawing?.isSeedAudioResourcePath == true ? nil : rawDrawing
        questionHTML = rawQuestionHTML.removingEmbeddedAudioControls
        let explicitAudioURL = try container.decodeFlexibleStringIfPresent(forKey: .audioURL)
            ?? container.decodeFlexibleStringIfPresent(forKey: .audioPath)
            ?? container.decodeFlexibleStringOrFirstArrayValueIfPresent(forKey: .audio)
        audioURL = explicitAudioURL
            ?? (rawDrawing?.isSeedAudioResourcePath == true ? rawDrawing : nil)
            ?? rawQuestionHTML.firstAudioSourcePath
        answerType = try container.decodeIfPresent(String.self, forKey: .answerType)
        answer = try container.decodeFlexibleStringIfPresent(forKey: .answer) ?? ""
        difficulty = try container.decodeFlexibleStringIfPresent(forKey: .difficulty)
        resourceID = try container.decodeFlexibleStringIfPresent(forKey: .resourceID)
            ?? container.decodeFlexibleStringIfPresent(forKey: .resource)
        let rawExplanationHTML = try container.decodeIfPresent(String.self, forKey: .explanationHTML)
        explanationEmbeddedImageCount = rawExplanationHTML?.embeddedImageCount ?? 0
        explanationHTML = rawExplanationHTML
        subject = try container.decodeIfPresent(String.self, forKey: .subject)
        exam = try container.decodeIfPresent(String.self, forKey: .exam)
    }

    func matches(dataset: SeedDataset) -> Bool {
        guard let exam else { return true }
        switch dataset.id {
        case .mathEGEBase:
            return exam.normalizedExamName == "егэ база"
        case .mathEGEProfile:
            return exam.normalizedExamName == "егэ профиль"
        case .mathOGE:
            return exam.normalizedExamName == "огэ" && subject?.normalizedSubjectName != "русский язык"
        case .mathVPR6:
            return exam.normalizedExamName == "впр 6"
        case .mathVPR7:
            return exam.normalizedExamName == "впр 7"
        case .mathVPR7Advanced:
            return exam.normalizedExamName == "впр 7 угл"
        case .mathVPR8:
            return exam.normalizedExamName == "впр8" || exam.normalizedExamName == "впр 8"
        case .mathVPR8Advanced:
            return exam.normalizedExamName == "впр 8 угл"
        case .russianEGE:
            return exam.normalizedExamName == "егэ"
        case .russianOGE:
            return exam.normalizedExamName == "огэ"
        case .russianVPR6:
            return exam.normalizedExamName == "впр6"
        case .russianVPR7:
            return exam.normalizedExamName == "впр7"
        case .russianVPR:
            return exam.normalizedExamName == "впр8" || exam.normalizedExamName == "впр"
        case .historyEGE:
            return exam.normalizedExamName == "егэ"
        case .historyOGE:
            return exam.normalizedExamName == "огэ"
        case .historyVPR6:
            return exam.normalizedExamName == "впр6"
        case .historyVPR7:
            return exam.normalizedExamName == "впр7"
        case .historyVPR8:
            return exam.normalizedExamName == "впр8" || exam.normalizedExamName == "впр"
        case .englishEGE:
            return exam.normalizedExamName == "егэ"
        case .englishOGE:
            return exam.normalizedExamName == "огэ"
        case .englishVPR6:
            return exam.normalizedExamName == "впр 6"
        case .englishVPR7:
            return exam.normalizedExamName == "впр 7"
        case .englishVPR8:
            return exam.normalizedExamName == "впр 8"
        case .biologyEGE, .computerScienceEGE, .physicsEGE, .chemistryEGE:
            return exam.normalizedExamName == "егэ"
        case .biologyOGE, .computerScienceOGE, .physicsOGE, .chemistryOGE:
            return exam.normalizedExamName == "огэ"
        }
    }

    func toDomainTask(
        subjectID: Subject.ID,
        examCategory: ExamCategory,
        level: String?,
        blockID: EducationalContentBlock.ID,
        drawingCodeByID: [String: String],
        drawingRefsByQuestionID: [String: [ExamUpSeedQuestionDrawing]]
    ) -> EducationalTask {
        let referencedTaskDrawing = resolvedDrawingContent(
            context: .task,
            drawingCodeByID: drawingCodeByID,
            drawingRefsByQuestionID: drawingRefsByQuestionID
        )
        let referencedExplanationDrawing = resolvedDrawingContent(
            context: .explanation,
            drawingCodeByID: drawingCodeByID,
            drawingRefsByQuestionID: drawingRefsByQuestionID
        )
        let resolvedAnswerDrawingURL = resolvedDrawingContent(
            context: .answer,
            drawingCodeByID: drawingCodeByID,
            drawingRefsByQuestionID: drawingRefsByQuestionID
        )

        let legacyDrawingParts = (drawingURL?.examDrawingParts ?? []).map { drawingCodeByID[$0] ?? $0 }
        let usesLegacyPartition = drawingRefsByQuestionID[id, default: []].isEmpty && !legacyDrawingParts.isEmpty
        let legacyTaskCount: Int
        if taskEmbeddedImageCount > 0 {
            legacyTaskCount = min(taskEmbeddedImageCount, legacyDrawingParts.count)
        } else if explanationEmbeddedImageCount > 0 {
            legacyTaskCount = 0
        } else {
            legacyTaskCount = legacyDrawingParts.count
        }
        let legacyExplanationStart = legacyTaskCount
        let legacyExplanationEnd = min(
            legacyDrawingParts.count,
            legacyExplanationStart + explanationEmbeddedImageCount
        )
        let resolvedDrawingURL = referencedTaskDrawing
            ?? (usesLegacyPartition ? legacyDrawingParts.prefix(legacyTaskCount).joined(separator: ";") : nil)
        let resolvedExplanationDrawingURL = referencedExplanationDrawing
            ?? (usesLegacyPartition && legacyExplanationEnd > legacyExplanationStart
                ? legacyDrawingParts[legacyExplanationStart..<legacyExplanationEnd].joined(separator: ";")
                : nil)

        return EducationalTask(
            id: id,
            questionNumber: questionNumber,
            topic: topic.trimmedOrFallback("Общий блок"),
            questionHTML: questionHTML,
            drawingURL: resolvedDrawingURL,
            explanationDrawingURL: resolvedExplanationDrawingURL,
            answerDrawingURL: resolvedAnswerDrawingURL,
            audioURL: audioURL,
            answerType: answerType,
            answer: answer,
            difficulty: difficulty,
            resourceID: resourceID,
            explanationHTML: explanationHTML,
            subjectID: subjectID,
            examCategory: examCategory,
            level: level,
            blockID: blockID
        )
    }

    private func resolvedDrawingContent(
        context: ExamUpSeedDrawingContext,
        drawingCodeByID: [String: String],
        drawingRefsByQuestionID: [String: [ExamUpSeedQuestionDrawing]]
    ) -> String? {
        let resolvedParts = drawingRefsByQuestionID[id, default: []]
            .filter { ExamUpSeedDrawingContext(rawValue: $0.context.normalizedDrawingContext) == context }
            .compactMap { drawingCodeByID[$0.drawingID] }
        return resolvedParts.isEmpty ? nil : resolvedParts.joined(separator: "\n")
    }
}

private enum ExamUpSeedDrawingContext: String {
    case task
    case explanation
    case answer
}

private extension KeyedDecodingContainer {
    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func decodeFlexibleStringOrFirstArrayValueIfPresent(forKey key: Key) throws -> String? {
        if let value = try decodeFlexibleStringIfPresent(forKey: key) {
            return value
        }
        return try? decodeIfPresent([String].self, forKey: key)?.first
    }
}

private extension String {
    func trimmedOrFallback(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    var normalizedExamName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    var normalizedSubjectName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
    }

    var normalizedDrawingContext: String {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
        switch value {
        case "solution", "решение", "explanation":
            return "explanation"
        case "answer", "ответ":
            return "answer"
        default:
            return "task"
        }
    }

    var isSeedAudioResourcePath: Bool {
        let lowercasedValue = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lowercasedValue.hasSuffix(".mp3")
            || lowercasedValue.hasSuffix(".m4a")
            || lowercasedValue.hasSuffix(".wav")
            || lowercasedValue.hasSuffix(".ogg")
    }
}
