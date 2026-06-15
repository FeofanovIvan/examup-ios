import SwiftUI

struct CalendarEmptyDayCTA: View {
    var body: some View {
        HStack(spacing: 14) {
            Image("Calendar3D")
                .resizable()
                .scaledToFit()
                .frame(width: 86, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text("На 22 мая событий нет")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: "101A2F"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("Отличный день, чтобы разобрать сложные темы!")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "4C515C"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            Button(action: {}) {
                HStack(spacing: 10) {
                    Text("Добавить\nсобытие")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 72)
                .background(Color(hex: "7257F4"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.045), radius: 18, x: 0, y: 10)
    }
}
