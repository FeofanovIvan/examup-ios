import Foundation

protocol SettingsServicing {
    func refreshSettings() async
}

struct PlaceholderSettingsService: SettingsServicing {
    func refreshSettings() async {}
}
