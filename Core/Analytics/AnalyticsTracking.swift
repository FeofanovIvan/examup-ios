import Foundation
import FirebaseAnalytics

protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
    func setUserID(_ userID: String?)
}

struct AnalyticsEvent: Equatable {
    let name: String
    let properties: [String: String]
}

struct NoOpAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
    func setUserID(_ userID: String?) {}
}

struct FirebaseAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.properties)
    }

    func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
    }
}
