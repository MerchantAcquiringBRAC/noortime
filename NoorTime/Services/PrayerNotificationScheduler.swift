import UserNotifications

/// Puts the planned reminders into iOS (and removes old ones).
@MainActor
struct PrayerNotificationScheduler {
    struct ScheduleOutcome: Equatable {
        var scheduled: Int
        var failed: Int
    }

    private let center: NotificationCenterProviding
    private let planner: PrayerNotificationPlanner

    init(center: NotificationCenterProviding,
         planner: PrayerNotificationPlanner = PrayerNotificationPlanner()) {
        self.center = center
        self.planner = planner
    }

    /// Replaces ALL of NoorTime's pending reminders with a fresh plan.
    /// Every reminder has a unique identifier ("noortime.prayer.<yyyyMMdd>.<prayer>"),
    /// so a reminder can never be scheduled twice.
    func reconcile(now: Date,
                   location: PrayerLocation,
                   settings: PrayerCalculationSettings,
                   preferences: NotificationPreferences,
                   language: String) async -> ScheduleOutcome {
        await cancelAll()

        let plan = planner.plan(now: now, location: location, settings: settings, preferences: preferences)
        var outcome = ScheduleOutcome(scheduled: 0, failed: 0)
        for item in plan {
            let request = Self.makeRequest(for: item, timeZone: location.timeZone, language: language)
            do {
                try await center.add(request)
                outcome.scheduled += 1
            } catch {
                outcome.failed += 1
            }
        }
        return outcome
    }

    /// Removes only NoorTime's own reminders.
    func cancelAll() async {
        let ours = await center.pendingIdentifiers()
            .filter { $0.hasPrefix(PrayerNotificationPlanner.identifierPrefix) }
        center.removePending(identifiers: ours)
    }

    static func makeRequest(for item: PlannedNotification,
                            timeZone: TimeZone,
                            language: String) -> UNNotificationRequest {
        let prayerName = Localizer.string(item.prayer.localizationKey, language: language)

        let content = UNMutableNotificationContent()
        content.title = prayerName
        content.body = String(format: Localizer.string("notification.body", language: language), prayerName)
        content.sound = UNNotificationSound(named: UNNotificationSoundName(NotificationSound.fileName))

        // The trigger is an exact moment, written in the PLACE's time zone (not the phone's).
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                 from: item.fireDate)
        components.calendar = calendar
        components.timeZone = timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        return UNNotificationRequest(identifier: item.identifier, content: content, trigger: trigger)
    }
}
