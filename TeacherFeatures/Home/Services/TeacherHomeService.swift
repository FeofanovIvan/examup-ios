import Foundation

protocol TeacherHomeServicing {
    func refreshTeacherWorkspace() async
}

struct PlaceholderTeacherHomeService: TeacherHomeServicing {
    func refreshTeacherWorkspace() async {}
}
