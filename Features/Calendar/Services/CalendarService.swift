import Foundation

protocol CalendarServicing {
    func refreshCalendar() async
}

struct PlaceholderCalendarService: CalendarServicing {
    func refreshCalendar() async {}
}
