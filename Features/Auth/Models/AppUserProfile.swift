import Foundation

struct AppUserProfile: Identifiable, Codable, Equatable {
    let id: String
    let publicId: String
    let name: String
    let email: String
    let role: AppUserRole
    let studentId: String?
    let teacherSubjectId: String?
    let teacherSubjectTitle: String?
}

extension AppUserProfile {
    init(user: AuthUser, name: String, role: AppUserRole, teacherSubject: Subject? = nil) {
        let profileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = user.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let publicId = AppUserIDGenerator.sixDigitID(from: user.id)

        self.id = user.id
        self.publicId = publicId
        self.name = profileName
        self.email = normalizedEmail
        self.role = role
        self.studentId = role == .student ? publicId : nil
        self.teacherSubjectId = role == .teacher ? teacherSubject?.id : nil
        self.teacherSubjectTitle = role == .teacher ? teacherSubject?.title : nil
    }
}
