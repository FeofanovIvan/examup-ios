import Foundation

protocol ExamServicing {
    func prepareExamSession() async
}

struct PlaceholderExamService: ExamServicing {
    func prepareExamSession() async {}
}
