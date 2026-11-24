import Foundation
import UserNotifications
@testable import NoorTime

/// Pretends to be iOS's notification center and records what was scheduled.
@MainActor
final class FakeNotificationCenter: NotificationCenterProviding {
    enum FakeError: Error { case rejected }

    var authorizationState: NotificationAuthorization
    var userAllowsWhenAsked: Bool
    var failingIdentifiers: Set<String> = []
    private(set) var requests: [String: UNNotificationRequest] = [:]
    private(set) var permissionPromptCount = 0

    init(authorization: NotificationAuthorization = .authorized, userAllowsWhenAsked: Bool = true) {
        self.authorizationState = authorization
        self.userAllowsWhenAsked = userAllowsWhenAsked
    }

    func authorization() async -> NotificationAuthorization {
        authorizationState
    }

    func requestAuthorization() async throws -> Bool {
        if authorizationState == .notDetermined {
            permissionPromptCount += 1
            authorizationState = userAllowsWhenAsked ? .authorized : .denied
        }
        return authorizationState == .authorized
    }

    func pendingIdentifiers() async -> [String] {
        Array(requests.keys)
    }

    func removePending(identifiers: [String]) {
        for identifier in identifiers {
            requests.removeValue(forKey: identifier)
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        if failingIdentifiers.contains(request.identifier) {
            throw FakeError.rejected
        }
        requests[request.identifier] = request
    }

    /// Puts a reminder in the "already pending" list, as if it had been scheduled earlier.
    func seed(_ identifier: String) {
        requests[identifier] = UNNotificationRequest(identifier: identifier,
                                                     content: UNMutableNotificationContent(),
                                                     trigger: nil)
    }
}

enum NotificationTestHelpers {
    /// The exact moment a request will fire, rebuilt from its calendar trigger.
    static func fireDate(of request: UNNotificationRequest, in timeZone: TimeZone) -> Date? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return nil }
        return TestSupport.calendar(timeZone).date(from: trigger.dateComponents)
    }

    static func makeStore() -> NotificationPreferencesStore {
        let name = "NoorTimeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return NotificationPreferencesStore(defaults: defaults)
    }
}

/// Fails for one particular day of the month, works for all others.
struct FlakyCalculator: PrayerTimeCalculating {
    let failingDayOfMonth: Int

    func entries(for date: Date,
                 location: PrayerLocation,
                 settings: PrayerCalculationSettings) throws -> [PrayerEntry] {
        let day = TestSupport.calendar(location.timeZone).component(.day, from: date)
        if day == failingDayOfMonth {
            throw PrayerTimeError.calculationFailed
        }
        return try StubCalculator().entries(for: date, location: location, settings: settings)
    }
}
