import Foundation

struct TeacherHomeSummary: Equatable {
    let displayName: String
    let publicId: String
    let studentsCount: Int
    let studentIDs: [String]
    let subjectTitle: String

    static let placeholder = TeacherHomeSummary(
        displayName: "Учитель",
        publicId: "000000",
        studentsCount: 0,
        studentIDs: [],
        subjectTitle: "Предмет не выбран"
    )
}

struct TeacherHomeActionCard: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let iconHex: String
    let backgroundHex: String
    let accentHex: String
    let assetName: String?
    let route: TeacherHomeRoute
}

struct TeacherHomeSection: Identifiable, Equatable {
    let id: String
    let pages: [TeacherHomeActionCard]

    static let dashboard: [TeacherHomeSection] = [
        TeacherHomeSection(
            id: "students",
            pages: [
                TeacherHomeActionCard(
                    id: "students",
                    title: "Ученики",
                    subtitle: "Управляйте учениками, просматривайте прогресс и результаты",
                    systemImage: "person.2.fill",
                    iconHex: "7257F4",
                    backgroundHex: "F6F1FF",
                    accentHex: "7257F4",
                    assetName: "students",
                    route: .students
                ),
                TeacherHomeActionCard(
                    id: "add_student",
                    title: "Добавить ученика",
                    subtitle: "Добавьте ученика по ID в локальный список",
                    systemImage: "person.badge.plus.fill",
                    iconHex: "7257F4",
                    backgroundHex: "F6F1FF",
                    accentHex: "7257F4",
                    assetName: "students",
                    route: .addStudent
                ),
                TeacherHomeActionCard(
                    id: "invite_student",
                    title: "Пригласить ученика",
                    subtitle: "Отправьте приглашение по email через уведомления",
                    systemImage: "envelope.badge.fill",
                    iconHex: "7257F4",
                    backgroundHex: "F6F1FF",
                    accentHex: "7257F4",
                    assetName: "students",
                    route: .inviteStudent
                )
            ]
        ),
        TeacherHomeSection(
            id: "assignments",
            pages: [
                TeacherHomeActionCard(
                    id: "constructor",
                    title: "Конструктор заданий",
                    subtitle: "Создавайте задания и экзамены, собирайте варианты",
                    systemImage: "list.clipboard.fill",
                    iconHex: "FF8A1F",
                    backgroundHex: "FFF3E8",
                    accentHex: "FF8A1F",
                    assetName: "list",
                    route: .assignmentConstructor
                ),
                TeacherHomeActionCard(
                    id: "assignment_history",
                    title: "История заданий",
                    subtitle: "Смотрите созданные работы, сроки и статусы учеников",
                    systemImage: "clock.arrow.circlepath",
                    iconHex: "FF8A1F",
                    backgroundHex: "FFF3E8",
                    accentHex: "FF8A1F",
                    assetName: "list",
                    route: .assignmentHistory
                )
            ]
        ),
        TeacherHomeSection(
            id: "settings",
            pages: [
                TeacherHomeActionCard(
                    id: "settings",
                    title: "Настройки",
                    subtitle: "Настройте профиль, предметы, уведомления и другие параметры",
                    systemImage: "gearshape.fill",
                    iconHex: "3F86E8",
                    backgroundHex: "EEF6FF",
                    accentHex: "3F86E8",
                    assetName: "gear",
                    route: .settings
                )
            ]
        )
    ]
}

enum TeacherHomeRoute: String, Hashable {
    case students
    case addStudent
    case inviteStudent
    case assignmentConstructor
    case assignmentHistory
    case settings
}
