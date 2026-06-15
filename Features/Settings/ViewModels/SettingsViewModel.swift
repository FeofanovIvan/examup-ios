import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    private let repository: SettingsRepository

    @Published private(set) var dashboard = SettingsDashboard.placeholder

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    func load() async {
        dashboard = (try? await repository.loadDashboard()) ?? .placeholder
    }
}
