import SwiftUI

struct CalendarWeekCard: View {
    let schedule: CalendarDaySchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text(schedule.monthTitle)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color(hex: "101A2F"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: "7257F4"))

                Button(action: {}) {
                    Text("Сегодня")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "7257F4"))
                        .padding(.horizontal, 18)
                        .frame(height: 42)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: "E7E1FF"), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: "7257F4"))
            }

            HStack(spacing: 0) {
                ForEach(schedule.weekDays) { day in
                    CalendarDayCell(day: day)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 22, x: 0, y: 12)
    }
}

private struct CalendarDayCell: View {
    let day: StudentCalendarDay

    var body: some View {
        VStack(spacing: 10) {
            Text(day.weekday)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "7D8494"))

            ZStack {
                if day.isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "7257F4"))
                        .frame(width: 50, height: 58)
                }

                VStack(spacing: 8) {
                    Text(day.number)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(dayTextColor)
                        .lineLimit(1)

                    Circle()
                        .fill(day.isSelected ? .white : Color(hex: "7257F4"))
                        .frame(width: 7, height: 7)
                        .opacity(day.hasEvent ? 1 : 0)
                }
            }
            .frame(height: 58)
        }
        .frame(maxWidth: .infinity)
    }

    private var dayTextColor: Color {
        if day.isSelected {
            return .white
        }

        return day.isWeekend ? Color(hex: "F04444") : Color(hex: "101A2F")
    }
}
