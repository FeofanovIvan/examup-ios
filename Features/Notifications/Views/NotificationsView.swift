import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel
    var onBack: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header

                if viewModel.isLoading {
                    loadingCard
                } else if viewModel.notifications.isEmpty {
                    emptyCard
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.notifications) { notification in
                            NotificationCard(
                                notification: notification,
                                isResolving: viewModel.resolvingNotificationID == notification.id,
                                onTap: { viewModel.markAsRead(notification) },
                                onAccept: { viewModel.resolveInvitation(notification, accept: true) },
                                onDecline: { viewModel.resolveInvitation(notification, accept: false) }
                            )
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF4D55"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                if let onBack {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .frame(width: 42, height: 42)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Уведомления")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)

                Text("Новые задания и важные сообщения")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "4C515C"))
            }

            Spacer()

            Text("\(viewModel.unreadCount)")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color(hex: "7257F4"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var loadingCard: some View {
        Text("Загружаем уведомления...")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(hex: "7B8194"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "7257F4"))
                .frame(width: 62, height: 62)
                .background(Color(hex: "F4F0FF"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Новых уведомлений нет")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            Text("Сообщения о заданиях от репетиторов появятся здесь.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "7B8194"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }
}

private struct NotificationCard: View {
    let notification: AppNotification
    let isResolving: Bool
    let onTap: () -> Void
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.type.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(notification.type.title)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(tint.opacity(0.12))
                            .clipShape(Capsule())

                        if !notification.isRead {
                            Circle()
                                .fill(Color(hex: "7257F4"))
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text(notification.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(2)

                    Text(notification.message)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "7B8194"))
                        .lineLimit(3)

                    Text(notification.createdAt.notificationDateTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "9AA1AF"))
                }

                Spacer(minLength: 6)
            }

            if notification.type == .invitation {
                invitationDetails
            }

            if notification.isPendingInvitation {
                HStack(spacing: 10) {
                    Button(action: onDecline) {
                        Text("Отклонить")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "FF4D55"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "FFF0F1"))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onAccept) {
                        Text(isResolving ? "Сохраняем..." : "Принять")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "29B765"))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .disabled(isResolving)
            } else if notification.type == .invitation, notification.status != .informational {
                Text(notification.status.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(statusTint)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(statusTint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: notification.isRead ? "E7E9F1" : "D8CEFF"), lineWidth: 1)
        }
        .shadow(color: Color(hex: "7257F4").opacity(notification.isRead ? 0.04 : 0.08), radius: 12, x: 0, y: 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var invitationDetails: some View {
        VStack(spacing: 7) {
            partyRow(title: "От кого", name: notification.senderName, email: notification.senderEmail)
            partyRow(title: "Кому", name: notification.recipientName, email: notification.recipientEmail)
        }
        .padding(10)
        .background(Color(hex: "FAF8FF"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func partyRow(title: String, name: String?, email: String?) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "8C94A3"))
                .frame(width: 58, alignment: .leading)

            Text([name, email].compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }.joined(separator: " · "))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "4C515C"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusTint: Color {
        notification.status == .accepted ? Color(hex: "29B765") : Color(hex: "FF4D55")
    }

    private var tint: Color {
        switch notification.type {
        case .assignment:
            return Color(hex: "7257F4")
        case .invitation:
            return Color(hex: "F28A2E")
        case .broadcast:
            return Color(hex: "C23A8B")
        case .personal:
            return Color(hex: "2F80ED")
        case .system:
            return Color(hex: "2F80ED")
        case .reminder:
            return Color(hex: "22A95A")
        }
    }
}

private extension Date {
    var notificationDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: self)
    }
}
