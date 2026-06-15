import SwiftUI

struct ExamAnswerDisplayView: View {
    let answer: String
    var drawingURL: String? = nil
    var resourceBaseURL: URL? = Bundle.main.resourceURL
    var emptyMessage = "Ответ не указан"

    @State private var answerHeight: CGFloat = 1
    @State private var drawingHeight: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if trimmedAnswer.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "8B92A3"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if trimmedAnswer.isLikelyLatexAnswer {
                ExamLatexAnswerWebView(
                    latex: trimmedAnswer,
                    keepsActiveFormulaOnOneLine: false,
                    height: $answerHeight
                )
                .frame(minHeight: max(answerHeight, 54))
            } else {
                Text(trimmedAnswer)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            let drawingParts = drawingURL?.examDrawingParts ?? []
            if !drawingParts.isEmpty {
                ExamHTMLWebView(
                    content: ExamContentRendering.drawingContent(from: drawingParts),
                    baseURL: resourceBaseURL,
                    height: $drawingHeight
                )
                .frame(height: max(drawingHeight, 96))
            }
        }
    }

    private var trimmedAnswer: String {
        answer.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    var isLikelyLatexAnswer: Bool {
        contains("\\") || contains("^") || contains("_")
    }
}
