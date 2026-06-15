import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol TeacherAssignmentHistoryRepository {
    func loadAssignments() async throws -> [TeacherAssignmentHistoryItem]
    func loadResult(for item: TeacherAssignmentHistoryItem) async throws -> ExamResultReport?
}

struct FirestoreTeacherAssignmentHistoryRepository: TeacherAssignmentHistoryRepository {
    private let database = Firestore.firestore()
    private let contentStore: EducationalContentStore

    init(contentStore: EducationalContentStore) {
        self.contentStore = contentStore
    }

    func loadAssignments() async throws -> [TeacherAssignmentHistoryItem] {
        guard let teacherID = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await database.collection("assignments")
            .whereField("teacherId", isEqualTo: teacherID)
            .getDocuments()

        var items: [TeacherAssignmentHistoryItem] = []
        for document in snapshot.documents {
            let data = document.data()
            let studentID = data["studentId"] as? String ?? ""
            let student = try? await database.collection("students").document(studentID).getDocument()
            let studentData = student?.data() ?? [:]
            items.append(
                TeacherAssignmentHistoryItem(
                    id: document.documentID,
                    title: data["title"] as? String ?? "Домашнее задание",
                    studentID: studentID,
                    studentName: studentData["name"] as? String ?? "Ученик",
                    studentPublicID: studentData["publicToken"] as? String ?? AppUserIDGenerator.sixDigitID(from: studentID),
                    dueAt: (data["dueAt"] as? Timestamp)?.dateValue() ?? Date(),
                    submittedAt: (data["submittedAt"] as? Timestamp)?.dateValue(),
                    versionID: data["variantVersionId"] as? String ?? "",
                    subjectID: data["subjectId"] as? String ?? "math"
                )
            )
        }
        return items.sorted { $0.dueAt > $1.dueAt }
    }

    func loadResult(for item: TeacherAssignmentHistoryItem) async throws -> ExamResultReport? {
        let submission = try await database.collection("submissions")
            .whereField("datasetId", isEqualTo: "teacher-assignment-\(item.id)")
            .limit(to: 1)
            .getDocuments()
            .documents.first
        guard let submission else { return nil }
        let data = submission.data()
        let answers = data["answers"] as? [String: String] ?? [:]
        let taskIDs = data["taskIds"] as? [String] ?? []
        let tasks = try await loadTasks(versionID: item.versionID, subjectID: item.subjectID)
        let safeModeReport = try? await loadSafeModeReport(sessionID: submission.documentID)
        let byID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let ordered = taskIDs.compactMap { byID[$0] }
        let reportTasks = ordered.isEmpty ? tasks : ordered

        return ExamResultReport(
            id: submission.documentID,
            title: item.title,
            subjectTitle: subjectTitle(for: item.subjectID),
            kindTitle: "Задание преподавателя",
            completedAt: (data["completedAt"] as? Timestamp)?.dateValue() ?? item.submittedAt ?? Date(),
            durationSeconds: data["actualDurationSeconds"] as? Int ?? 0,
            safeSessionValid: data["safeSessionValid"] as? Bool ?? false,
            safeModeReport: safeModeReport,
            items: reportTasks.enumerated().map { index, task in
                ExamResultReportItem(
                    id: task.id,
                    subjectID: task.subjectID,
                    number: task.questionNumber ?? "\(index + 1)",
                    topic: task.topic,
                    questionHTML: task.questionHTML,
                    drawingURL: task.drawingURL,
                    audioURL: task.audioURL,
                    userAnswer: answers[task.id],
                    correctAnswer: task.answer,
                    answerDrawingURL: task.answerDrawingURL,
                    explanationHTML: task.explanationHTML,
                    explanationDrawingURL: task.explanationDrawingURL
                )
            }
        )
    }

    private func loadSafeModeReport(sessionID: String) async throws -> ExamSafeModeReport? {
        let snapshot = try await database.collection("safemode_reports").document(sessionID).getDocument()
        guard let data = snapshot.data() else { return nil }
        let flags = (data["flags"] as? [String] ?? []).compactMap(ExamSafeModeFlag.init(rawValue:))
        let verdict = ExamSafeModeVerdict(rawValue: data["verdict"] as? String ?? "") ?? .clean
        return ExamSafeModeReport(
            id: sessionID,
            sessionID: sessionID,
            generatedAt: (data["generatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            score: data["score"] as? Int ?? 0,
            verdict: verdict,
            summary: data["summary"] as? String ?? "",
            totalCaptureCount: data["totalCaptureCount"] as? Int ?? 0,
            captureFindingsCount: data["captureFindingsCount"] as? Int ?? 0,
            transcriptFindingsCount: data["transcriptFindingsCount"] as? Int ?? 0,
            flags: flags
        )
    }

    private func loadTasks(versionID: String, subjectID: String) async throws -> [EducationalTask] {
        let snapshot = try await database.collection("assignmentVariantVersions")
            .document(versionID).collection("items").getDocuments()
        let documents = snapshot.documents.sorted {
            ($0.data()["position"] as? Int ?? 0) < ($1.data()["position"] as? Int ?? 0)
        }
        var tasks: [EducationalTask] = []
        for document in documents {
            let data = document.data()
            if data["kind"] as? String == TeacherAssignmentItemKind.seed.rawValue,
               let datasetID = data["datasetId"] as? String,
               let taskID = data["taskId"] as? String,
               let source = try await contentStore.loadDatabase(datasetID: datasetID),
               let task = source.tasks.first(where: { $0.id == taskID }) {
                tasks.append(task)
            } else if data["kind"] as? String == TeacherAssignmentItemKind.custom.rawValue {
                let contentType = data["attachmentContentType"] as? String ?? ""
                tasks.append(EducationalTask(
                    id: document.documentID,
                    questionNumber: "\(tasks.count + 1)",
                    topic: "Задание преподавателя",
                    questionHTML: data["taskText"] as? String ?? "",
                    drawingURL: contentType.hasPrefix("image/") ? data["attachmentUrl"] as? String : nil,
                    explanationDrawingURL: nil,
                    answerDrawingURL: nil,
                    audioURL: nil,
                    answerType: nil,
                    answer: data["answerText"] as? String ?? "",
                    difficulty: nil,
                    resourceID: nil,
                    explanationHTML: data["explanationText"] as? String,
                    subjectID: subjectID,
                    examCategory: .constructor,
                    level: nil,
                    blockID: "teacher-assignment"
                ))
            }
        }
        return tasks
    }

    private func subjectTitle(for id: String) -> String {
        switch id {
        case "math": return "Математика"
        case "russian": return "Русский язык"
        case "history": return "История"
        default: return "Предмет"
        }
    }
}
