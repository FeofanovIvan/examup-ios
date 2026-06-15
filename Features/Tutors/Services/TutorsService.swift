import Foundation

protocol TutorsServicing {
    func refreshAssignments() async
}

struct PlaceholderTutorsService: TutorsServicing {
    func refreshAssignments() async {}
}
