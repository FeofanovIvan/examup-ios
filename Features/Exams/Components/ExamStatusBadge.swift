import SwiftUI

struct ExamStatusBadge: View {
    let status: ExamSessionStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }
}
