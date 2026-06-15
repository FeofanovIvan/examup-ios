import SwiftUI

struct DaySchedulePlaceholder: View {
    let schedule: CalendarDaySchedule

    var body: some View {
        PlaceholderBlock(title: "Day Schedule", subtitle: "\(schedule.events.count) events")
    }
}
