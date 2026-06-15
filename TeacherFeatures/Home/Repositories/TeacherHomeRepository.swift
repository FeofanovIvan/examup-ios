import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol TeacherHomeRepository {
    func loadSummary() async throws -> TeacherHomeSummary
}

struct PlaceholderTeacherHomeRepository: TeacherHomeRepository {
    func loadSummary() async throws -> TeacherHomeSummary {
        .placeholder
    }
}

struct FirestoreTeacherHomeRepository: TeacherHomeRepository {
    private let database = Firestore.firestore()

    func loadSummary() async throws -> TeacherHomeSummary {
        guard let user = Auth.auth().currentUser else {
            return .placeholder
        }

        let publicId = AppUserIDGenerator.sixDigitID(from: user.uid)
        let teacherDocument = try? await database
            .collection("teachers")
            .document(user.uid)
            .getDocument()
        let data = teacherDocument?.data() ?? [:]
        let students = data["studentIds"] as? [String]
        let studentsCount = data["studentsCount"] as? Int ?? students?.count ?? 0
        let displayName = (data["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let subjectTitle = (data["subjectTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = displayName?.isEmpty == false ? displayName : user.displayName
        let resolvedSubject = subjectTitle?.isEmpty == false ? subjectTitle : nil

        return TeacherHomeSummary(
            displayName: resolvedName ?? "Учитель",
            publicId: data["publicToken"] as? String ?? publicId,
            studentsCount: studentsCount,
            studentIDs: students ?? [],
            subjectTitle: resolvedSubject ?? "Предмет не выбран"
        )
    }
}
