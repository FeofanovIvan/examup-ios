import SwiftUI

struct ExamSessionPlaceholderView: View {
    @StateObject var viewModel: ExamSessionViewModel

    var body: some View {
        ScreenContainer(title: "Exam Session") {
            PlaceholderBlock(
                title: "Exam Session Foundation",
                subtitle: viewModel.activeSession?.status.rawValue ?? "No active session"
            )
        }
        .task {
            await viewModel.loadActiveSession()
        }
    }
}
