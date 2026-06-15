import SwiftUI

struct HomeExamBlockCard: View {
    let block: HomeExamBlock
    var onSelect: (HomeExamBlock) -> Void = { _ in }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: block.backgroundHex),
                            .white.opacity(0.72)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            HStack(alignment: .center, spacing: 6) {
                VStack(alignment: .leading, spacing: 11) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(block.title)
                            .font(.system(size: block.id == "constructor" ? 22 : 28, weight: .bold))
                            .foregroundStyle(Color(hex: "20242D"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(block.subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .lineSpacing(2)
                            .foregroundStyle(Color(hex: "3F444D"))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(2)

                    actionButton(for: block)
                }
                .padding(.leading, 18)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(2)

                Image(block.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 98, height: 96)
                    .padding(.trailing, 8)
                    .layoutPriority(0)
            }
        }
        .frame(minHeight: 148)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            onSelect(block)
        }
    }

    private func actionButton(for block: HomeExamBlock) -> some View {
        Button(action: { onSelect(block) }) {
            Text(block.actionTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color(hex: block.tintHex))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
