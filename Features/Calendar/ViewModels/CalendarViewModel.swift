import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    private let repository: CalendarRepository
    private var allItems: [ExamHistoryItem] = []

    @Published private(set) var dashboard = ExamHistoryDashboard.empty
    @Published var resultReport: ExamResultReport?
    /// Non-nil when the share sheet should be presented. Set to nil on dismiss.
    @Published var shareURLs: [URL]? = nil
    /// True while the ZIP is being prepared.
    @Published private(set) var isPrepairingShare = false

    init(repository: CalendarRepository) {
        self.repository = repository
    }

    func load() async {
        allItems = (try? await repository.loadHistoryItems()) ?? []
        let initialDate = allItems.first?.completedAt ?? Date()
        dashboard = ExamHistoryDashboard(selectedDate: initialDate, items: items(for: initialDate))
    }

    func moveDay(by value: Int) {
        guard let date = Calendar.current.date(byAdding: .day, value: value, to: dashboard.selectedDate) else { return }
        dashboard = ExamHistoryDashboard(selectedDate: date, items: items(for: date))
    }

    func deleteItem(id: ExamHistoryItem.ID) {
        Task {
            try? await repository.deleteHistoryItem(id: id)
            allItems.removeAll { $0.id == id }
            dashboard = ExamHistoryDashboard(
                selectedDate: dashboard.selectedDate,
                items: items(for: dashboard.selectedDate)
            )
        }
    }

    func showResult(id: ExamHistoryItem.ID) {
        Task {
            resultReport = try? await repository.loadResultReport(id: id)
        }
    }

    func prepareShare(for id: ExamHistoryItem.ID) {
        guard !isPrepairingShare else { return }
        isPrepairingShare = true
        Task {
            let urls = await ExamArchiveShareService.shareURLs(for: id)
            isPrepairingShare = false
            if urls.isEmpty {
                // No archive for this session — nothing to share
                #if DEBUG
                print("[CalendarViewModel] no archive found for session=\(id)")
                #endif
            } else {
                shareURLs = urls
            }
        }
    }

    private func items(for date: Date) -> [ExamHistoryItem] {
        allItems.filter {
            Calendar.current.isDate($0.completedAt, inSameDayAs: date)
        }
    }
}
