import SwiftUI

struct ExamDraftSheet: View {
    @ObservedObject var canvasState: DrawingCanvasState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TaskDrawingView(canvasState: canvasState)
                .navigationTitle("Черновик")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "20242D"))
                                .frame(width: 34, height: 34)
                                .background(Color(hex: "F1F3F7"))
                                .clipShape(Circle())
                        }
                    }
                }
        }
    }
}
