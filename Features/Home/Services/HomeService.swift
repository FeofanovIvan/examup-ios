import Foundation

protocol HomeServicing {
    func refreshHome() async
}

struct PlaceholderHomeService: HomeServicing {
    func refreshHome() async {}
}
