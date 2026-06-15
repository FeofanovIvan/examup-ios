import SwiftUI

struct CalendarEventCard: View {
    let event: StudentCalendarEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(event.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .padding(10)
                .background(Color(hex: event.backgroundHex))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Rectangle()
                .fill(Color(hex: event.tintHex).opacity(0.24))
                .frame(width: 2, height: 88)

            VStack(alignment: .leading, spacing: 7) {
                Label(event.time, systemImage: "clock")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: event.tintHex))
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Color(hex: event.backgroundHex))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(event.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "101A2F"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(event.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "596174"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Label(event.owner, systemImage: "person")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: event.tintHex))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {}) {
                VStack(spacing: 6) {
                    Image(systemName: "bell")
                        .font(.system(size: 26, weight: .medium))
                    Text("Напомнить")
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(Color(hex: event.tintHex))
                .frame(width: 78, height: 82)
                .background(Color(hex: event.backgroundHex))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.045), radius: 18, x: 0, y: 10)
    }
}
