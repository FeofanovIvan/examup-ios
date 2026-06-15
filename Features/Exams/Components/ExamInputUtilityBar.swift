import SwiftUI

struct ExamInputUtilityBar: View {
    let onDraft: () -> Void
    let onPanel: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            utilityButton(title: "Черновик", systemImage: "pencil.tip", action: onDraft)
            utilityButton(title: "Панель", systemImage: "sidebar.right", action: onPanel)
            utilityButton(title: "Очистить", systemImage: "eraser", action: onClear)
        }
    }

    private func utilityButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(Color(hex: "20242D"))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
