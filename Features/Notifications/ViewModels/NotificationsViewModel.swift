import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    private let repository: NotificationsRepository

    @Published private(set) var notifications: [AppNotification] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var resolvingNotificationID: String?

    init(repository: NotificationsRepository) {
        self.repository = repository
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            notifications = try await repository.loadNotifications()
        } catch {
            errorMessage = "Не удалось загрузить уведомления"
            notifications = []
            #if DEBUG
            print("[Notifications] load failed: \(error.localizedDescription)")
            #endif
        }
    }

    func listenForUpdates() async {
        isLoading = notifications.isEmpty
        errorMessage = nil

        do {
            for try await updatedNotifications in repository.notificationUpdates() {
                notifications = updatedNotifications
                isLoading = false
            }
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Не удалось обновить уведомления"
        }
    }

    func markAsRead(_ notification: AppNotification) {
        guard !notification.isRead else { return }
        Task {
            try? await repository.markAsRead(notification)
        }
    }

    func resolveInvitation(_ notification: AppNotification, accept: Bool) {
        guard notification.isPendingInvitation else { return }
        resolvingNotificationID = notification.id
        errorMessage = nil

        Task {
            do {
                try await repository.resolveInvitation(notification, accept: accept)
            } catch {
                errorMessage = accept
                    ? "Не удалось принять запрос"
                    : "Не удалось отклонить запрос"
            }
            resolvingNotificationID = nil
        }
    }
}
