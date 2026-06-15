import SwiftUI

struct PremiumSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlanID = PremiumSubscriptionPlan.yearly.id
    @State private var isPurchaseMessagePresented = false

    private let plans = PremiumSubscriptionPlan.available

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    benefitsCard
                    plansSection
                    footerLinks
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }

            bottomAction
        }
        .background(Color(hex: "FBFCFF"))
        .alert("Премиум", isPresented: $isPurchaseMessagePresented) {
            Button("Ок", role: .cancel) {}
        } message: {
            Text("Экран готов. Подключение оплаты добавим через StoreKit отдельным шагом.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .frame(width: 42, height: 42)
                        .background(.white)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Spacer()
            }

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "8D72FF"), Color(hex: "5E3FE8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("ExamUp Premium")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("Больше практики, отчетов и возможностей для подготовки")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "687083"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Что входит")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            PremiumBenefitRow(
                icon: "doc.text.magnifyingglass",
                title: "Подробные отчеты",
                subtitle: "Разбор ответов, вопросов и результатов"
            )

            PremiumBenefitRow(
                icon: "square.stack.3d.up.fill",
                title: "Больше вариантов",
                subtitle: "Расширенный доступ к экзаменам и конструктору"
            )

            PremiumBenefitRow(
                icon: "archivebox.fill",
                title: "Архив экзаменов",
                subtitle: "Хранение истории, отчетов и материалов сессий"
            )
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Выберите подписку")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "20242D"))

            ForEach(plans) { plan in
                PremiumPlanCard(
                    plan: plan,
                    isSelected: selectedPlanID == plan.id
                ) {
                    selectedPlanID = plan.id
                }
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button("Восстановить покупки") {}
            Button("Условия") {}
            Button("Политика") {}
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(Color(hex: "7257F4"))
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var bottomAction: some View {
        VStack(spacing: 10) {
            Button {
                isPurchaseMessagePresented = true
            } label: {
                Text("Подключить Premium")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "7257F4"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Text(selectedPlan.renewalText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "8C94A3"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "E7E9F1"))
                .frame(height: 1)
        }
    }

    private var selectedPlan: PremiumSubscriptionPlan {
        plans.first { $0.id == selectedPlanID } ?? PremiumSubscriptionPlan.yearly
    }
}

private struct PremiumPlanCard: View {
    let plan: PremiumSubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "7257F4") : Color(hex: "DDE1EA"), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "7257F4"))
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "20242D"))

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "7257F4"))
                                .padding(.horizontal, 8)
                                .frame(height: 22)
                                .background(Color(hex: "F1EBFF"))
                                .clipShape(Capsule())
                        }
                    }

                    Text(plan.subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "687083"))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(plan.price)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))

                    Text(plan.period)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "8C94A3"))
                }
            }
            .padding(14)
            .background(isSelected ? Color(hex: "F6F2FF") : .white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color(hex: "7257F4") : Color(hex: "E7E9F1"), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PremiumBenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "7257F4"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "F1EBFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
                    .lineLimit(2)
            }
        }
    }
}

private struct PremiumSubscriptionPlan: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let price: String
    let period: String
    let badge: String?
    let renewalText: String

    static let monthly = PremiumSubscriptionPlan(
        id: "monthly",
        title: "Ежемесячная",
        subtitle: "Гибкий доступ на один месяц",
        price: "399 ₽",
        period: "в месяц",
        badge: nil,
        renewalText: "Подписка будет продлеваться каждый месяц."
    )

    static let quarterly = PremiumSubscriptionPlan(
        id: "quarterly",
        title: "На 3 месяца",
        subtitle: "Удобно для учебного периода",
        price: "999 ₽",
        period: "333 ₽ / мес",
        badge: "Популярно",
        renewalText: "Подписка будет продлеваться каждые 3 месяца."
    )

    static let yearly = PremiumSubscriptionPlan(
        id: "yearly",
        title: "Годовая",
        subtitle: "Лучший вариант для подготовки к экзаменам",
        price: "2 990 ₽",
        period: "249 ₽ / мес",
        badge: "Выгодно",
        renewalText: "Подписка будет продлеваться один раз в год."
    )

    static let available: [PremiumSubscriptionPlan] = [
        monthly,
        quarterly,
        yearly
    ]
}
