import SwiftUI

struct ExamResultReportView: View {
    let report: ExamResultReport
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    summaryCard

                    ForEach(report.items) { item in
                        ExamResultReportItemView(item: item)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(hex: "FBFCFF"))
            .navigationTitle("Результат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово", action: onClose)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(reportPurple)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.subjectTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(reportInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("\(report.kindTitle) · \(formattedDate(report.completedAt))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "747C91"))
                }

                Spacer()

                Text(report.safeSessionValid ? "Безопасно" : "Не безопасно")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(report.safeSessionValid ? Color(hex: "22A95A") : Color(hex: "EF4444"))
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(report.safeSessionValid ? Color(hex: "EAF8EF") : Color(hex: "FFF0F1"))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                summaryMetric(title: "Ответов", value: "\(report.answeredCount)/\(report.totalCount)")
                summaryMetric(title: "Время", value: formattedDuration(report.durationSeconds))
            }

            if let sm = report.safeModeReport {
                safeModeScoreRow(sm)
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: "E7E2FF"), lineWidth: 1)
        }
        .shadow(color: reportPurple.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    @ViewBuilder
    private func safeModeScoreRow(_ sm: ExamSafeModeReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Score bar + label
            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(hex: "EFEFEF"))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(verdictColor(sm.verdict))
                            .frame(width: geo.size.width * CGFloat(sm.score) / 100.0, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(sm.score)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(verdictColor(sm.verdict))
                    .frame(width: 38, alignment: .trailing)
            }

            // Verdict chip + summary
            HStack(alignment: .top, spacing: 8) {
                Text(sm.verdict.localizedTitle)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(verdictColor(sm.verdict))
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(verdictColor(sm.verdict).opacity(0.12))
                    .clipShape(Capsule())

                Text(sm.summary)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: "747C91"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color(hex: "F9F8FF"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func verdictColor(_ verdict: ExamSafeModeVerdict) -> Color {
        switch verdict {
        case .clean:      return Color(hex: "22A95A")
        case .suspicious: return Color(hex: "F5A623")
        case .cheating:   return Color(hex: "EF4444")
        }
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "747C91"))
            Text(value)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(reportInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(Color(hex: "F6F3FF"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        if hours > 0 {
            return "\(hours) ч \(minutes) мин"
        }
        return "\(max(minutes, 1)) мин"
    }

    private var reportPurple: Color { Color(hex: "7257F4") }
    private var reportInk: Color { Color(hex: "20242D") }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter
    }()
}

private struct ExamResultReportItemView: View {
    let item: ExamResultReportItem
    @State private var isExpanded = false
    @State private var questionHeight: CGFloat = 1
    @State private var explanationHeight: CGFloat = 1

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                ExamHTMLWebView(
                    content: ExamContentRendering.unifiedHTML(
                        primaryHTML: item.questionHTML,
                        drawingURL: item.drawingURL
                    ),
                    baseURL: resourceBaseURL,
                    height: $questionHeight
                )
                    .frame(height: max(questionHeight, 88))

                if let audioURL = item.audioURL, !audioURL.isEmpty {
                    ExamAudioPlayerView(source: audioURL)
                }

                answerBlock(
                    title: "Ваш ответ",
                    answer: item.userAnswer ?? "",
                    drawingURL: nil,
                    isEmpty: !item.hasUserAnswer
                )

                answerBlock(
                    title: "Правильный ответ",
                    answer: item.correctAnswer,
                    drawingURL: item.answerDrawingURL,
                    isEmpty: item.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                if hasExplanation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Образец развёрнутого ответа" : "Пояснение")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(reportInk)

                        if let explanationHTML = item.explanationHTML?.renderableExamExplanationHTML, !explanationHTML.isEmpty {
                            ExamHTMLWebView(
                                content: ExamContentRendering.unifiedHTML(
                                    primaryHTML: explanationHTML,
                                    drawingURL: item.explanationDrawingURL
                                ),
                                baseURL: resourceBaseURL,
                                revealsHiddenContent: true,
                                height: $explanationHeight
                            )
                            .frame(height: max(explanationHeight, 96))
                        } else if let drawingURL = item.explanationDrawingURL {
                            ExamHTMLWebView(
                                content: ExamContentRendering.unifiedHTML(
                                    primaryHTML: "",
                                    drawingURL: drawingURL
                                ),
                                baseURL: resourceBaseURL,
                                height: $explanationHeight
                            )
                            .frame(height: max(explanationHeight, 96))
                        }
                    }
                }
            }
            .padding(.top, 14)
        } label: {
            HStack(spacing: 12) {
                Text(item.number)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(item.hasUserAnswer ? .white : reportPurple)
                    .frame(width: 38, height: 38)
                    .background(item.hasUserAnswer ? reportPurple : Color(hex: "F4F0FF"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Вопрос \(item.number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(reportInk)
                    Text(item.topic)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "747C91"))
                        .lineLimit(1)
                }

                Spacer()

                Text(item.hasUserAnswer ? "Есть ответ" : "Нет ответа")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(item.hasUserAnswer ? Color(hex: "22A95A") : Color(hex: "EF4444"))
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(item.hasUserAnswer ? Color(hex: "EAF8EF") : Color(hex: "FFF0F1"))
                    .clipShape(Capsule())
            }
        }
        .tint(reportPurple)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "E7EAF2"), lineWidth: 1)
        }
        .shadow(color: reportPurple.opacity(0.06), radius: 14, x: 0, y: 7)
    }

    private var resourceBaseURL: URL? {
        guard let subjectID = item.subjectID else {
            return Bundle.main.resourceURL
        }
        return SubjectLibraryCatalog.resourceBaseURL(for: subjectID) ?? Bundle.main.resourceURL
    }

    private func answerBlock(title: String, answer: String, drawingURL: String?, isEmpty: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(isEmpty ? Color(hex: "9AA1AF") : reportInk)

            ExamAnswerDisplayView(
                answer: answer,
                drawingURL: drawingURL,
                resourceBaseURL: resourceBaseURL,
                emptyMessage: item.explanationHTML?.trimmedExamHTML.isEmpty == false
                    ? "Развёрнутый ответ приведён ниже"
                    : "Ответ не указан"
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "FBFCFF"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "E7EAF2"), lineWidth: 1)
            }
        }
    }

    private var hasExplanation: Bool {
        item.explanationHTML?.trimmedExamHTML.isEmpty == false
            || !(item.explanationDrawingURL?.examDrawingParts.isEmpty ?? true)
    }

    private var reportPurple: Color { Color(hex: "7257F4") }
    private var reportInk: Color { Color(hex: "20242D") }
}
