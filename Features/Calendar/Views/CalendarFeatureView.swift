import SwiftUI

struct CalendarFeatureView: View {
    @StateObject var viewModel: CalendarViewModel

    var body: some View {
        ExamHistoryView(viewModel: viewModel)
            .task {
                await viewModel.load()
            }
            .sheet(item: $viewModel.resultReport) { report in
                ExamResultReportView(report: report) {
                    viewModel.resultReport = nil
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.shareURLs != nil },
                set: { if !$0 { viewModel.shareURLs = nil } }
            )) {
                ActivityView(items: viewModel.shareURLs ?? []) {
                    viewModel.shareURLs = nil
                }
            }
            .overlay {
                if viewModel.isPrepairingShare {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView("Подготовка архива…")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(24)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
    }
}

private struct ExamHistoryView: View {
    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                dateSelector

                if viewModel.dashboard.items.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.dashboard.items) { item in
                            ExamHistoryCard(
                                item: item,
                                onShowResult: {
                                    viewModel.showResult(id: item.id)
                                },
                                onShare: {
                                    viewModel.prepareShare(for: item.id)
                                },
                                onDelete: {
                                    viewModel.deleteItem(id: item.id)
                                }
                            )
                        }
                    }

                    Text("Показано \(viewModel.dashboard.items.count) из \(viewModel.dashboard.items.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "8B91A3"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("История")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Ваши выполненные экзамены")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "4C515C"))
            }

            Spacer()

            Button(action: {}) {
                Label("Фильтр", systemImage: "line.3.horizontal.decrease")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
                    .frame(width: 96, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var dateSelector: some View {
        HStack(spacing: 12) {
            historyArrowButton(systemName: "chevron.left") {
                viewModel.moveDay(by: -1)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))

                Text(viewModel.dashboard.selectedDate.historyDayTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            historyArrowButton(systemName: "chevron.right") {
                viewModel.moveDay(by: 1)
            }
        }
        .padding(.top, 2)
    }

    private func historyArrowButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "7257F4"))
                .frame(width: 42, height: 42)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "7257F4"))
                .frame(width: 62, height: 62)
                .background(Color(hex: "F4F0FF"))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("За этот день экзаменов нет")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "101A2F"))

            Text("Завершенные работы появятся здесь после сдачи экзамена.")
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

private struct ExamHistoryCard: View {
    let item: ExamHistoryItem
    let onShowResult: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                subjectIcon

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.subjectTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    HStack(spacing: 8) {
                        Text(item.kindTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(kindTint)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(kindTint.opacity(0.14))
                            .clipShape(Capsule())

                        Text(item.detail)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "7B8194"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }

                Spacer(minLength: 6)

                Button(action: onShowResult) {
                    Text("Результат")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(Color(hex: "F4F0FF"))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                historyMetric(systemImage: "calendar", title: item.completedAt.historyTimeTitle)
                historyMetric(systemImage: "clock", title: item.durationSeconds.historyDurationTitle)

                if !item.safeSessionValid {
                    Text("Safe не засчитан")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "EF8A24"))
                        .padding(.horizontal, 8)
                        .frame(height: 28)
                        .background(Color(hex: "FFF4E8"))
                        .clipShape(Capsule())
                }
            }

            Rectangle()
                .fill(Color(hex: "EEF0F6"))
                .frame(height: 1)

            HStack {
                Button(action: onShare) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "7257F4"))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onDelete) {
                    Label("Удалить", systemImage: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "FF4D55"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.045), radius: 12, x: 0, y: 6)
    }

    private func historyMetric(systemImage: String, title: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color(hex: "7257F4"))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 9)
            .frame(height: 30)
            .background(Color(hex: "F7F4FF"))
            .clipShape(Capsule())
    }

    private var subjectIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(kindTint.opacity(0.14))

            Text(subjectSymbol)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(kindTint)
        }
        .frame(width: 50, height: 50)
    }

    private var subjectSymbol: String {
        switch item.subjectID {
        case "math": return "√x"
        case "russian": return "Ру"
        case "history": return "И"
        default: return "Ex"
        }
    }

    private var kindTint: Color {
        switch item.kindTitle {
        case "ОГЭ": return Color(hex: "4D8DF7")
        case "Конструктор": return Color(hex: "FB8A2E")
        default: return Color(hex: "7257F4")
        }
    }
}

private extension Date {
    var historyDayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: self)
    }

    var historyTimeTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: self)
    }
}

private extension Int {
    var historyDurationTitle: String {
        let minutes = Swift.max(0, self / 60)
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 && remainder > 0 {
            return "\(hours) ч \(remainder) мин"
        }
        if hours > 0 {
            return "\(hours) ч"
        }
        return "\(remainder) мин"
    }
}
