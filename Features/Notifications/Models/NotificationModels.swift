import Foundation

struct AppNotification: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let type: AppNotificationType
    let createdAt: Date
    let isRead: Bool
    let assignmentID: String?
    let requestID: String?
    let senderID: String?
    let senderName: String?
    let senderEmail: String?
    let recipientID: String?
    let recipientName: String?
    let recipientEmail: String?
    let status: AppNotificationStatus
    let sourcePath: String

    var isPendingInvitation: Bool {
        type == .invitation && status == .pending && requestID != nil
    }

    static let sampleAssignments = [
        AppNotification(
            id: "sample-assignment-1",
            title: "Новое задание",
            message: "Репетитор добавил вариант для подготовки. Откройте задание и начните выполнение.",
            type: .assignment,
            createdAt: Date(),
            isRead: false,
            assignmentID: nil,
            requestID: nil,
            senderID: nil,
            senderName: nil,
            senderEmail: nil,
            recipientID: nil,
            recipientName: nil,
            recipientEmail: nil,
            status: .pending,
            sourcePath: "notifications/assignments/items/sample-assignment-1"
        )
    ]
}

enum AppNotificationStatus: String, Codable, Equatable {
    case pending
    case accepted
    case declined
    case informational

    var title: String {
        switch self {
        case .pending: return "Ожидает решения"
        case .accepted: return "Принято"
        case .declined: return "Отклонено"
        case .informational: return ""
        }
    }
}

enum AppNotificationType: String, Codable, Equatable {
    case assignment
    case invitation
    case broadcast = "all"
    case personal
    case system
    case reminder

    var title: String {
        switch self {
        case .assignment:
            return "Задание"
        case .invitation:
            return "Приглашение"
        case .broadcast:
            return "Для всех"
        case .personal:
            return "Личное"
        case .system:
            return "Система"
        case .reminder:
            return "Напоминание"
        }
    }

    var symbolName: String {
        switch self {
        case .assignment:
            return "doc.text.fill"
        case .invitation:
            return "person.badge.plus.fill"
        case .broadcast:
            return "megaphone.fill"
        case .personal:
            return "person.crop.circle.fill"
        case .system:
            return "bell.fill"
        case .reminder:
            return "clock.fill"
        }
    }
}
