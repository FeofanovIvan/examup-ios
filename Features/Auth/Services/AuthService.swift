import Foundation

protocol AuthServicing {
    func prepareAuthenticationFlow() async
}

struct PlaceholderAuthService: AuthServicing {
    func prepareAuthenticationFlow() async {}
}
