import XCTest
import UserNotifications
@testable import NoorTime

@MainActor
final class PrayerNotificationSchedulerTests: XCTestCase {
    private let now = TestSupport.date(2026, 11, 11, 10, 0)

    private func makeScheduler(_ center: FakeNotificationCenter) -> PrayerNotificationScheduler {
        PrayerNotificationScheduler(center: center,
                                    planner: PrayerNotificationPlanner(calculator: StubCalculator()))
    }

    private func reconcile(_ scheduler: PrayerNotificationScheduler,
                           location: PrayerLocation = TestSupport.dhakaLocation,
                           now: Date? = nil,
                           language: String = "en",
                           preferences: NotificationPreferences = NotificationPreferences())
    async -> PrayerNotificationScheduler.ScheduleOutcome {
        await scheduler.reconcile(now: now ?? self.now,
                                  location: location,
                                  settings: .bangladeshDefault,
                                  preferences: preferences,
                                  language: language)
    }

    func testSchedulesOneRequestPerPlannedReminder() async {
        let center = FakeNotificationCenter()
        let outcome = await reconcile(makeScheduler(center))
        XCTAssertEqual(outcome, .init(scheduled: 59, failed: 0))
        XCTAssertEqual(center.requests.count, 59)
    }

    func testEnglishContentAndSound() async throws {
        let center = FakeNotificationCenter()
        _ = await reconcile(makeScheduler(center))
        let request = try XCTUnwrap(center.requests["noortime.prayer.20261111.dhuhr"])
        XCTAssertEqual(request.content.title, "Dhuhr")
        XCTAssertEqual(request.content.body, "It is time for Dhuhr prayer.")
        XCTAssertNotNil(request.content.sound)
    }

    func testBengaliContent() async throws {
        let center = FakeNotificationCenter()
        _ = await reconcile(makeScheduler(center), language: "bn")
        let request = try XCTUnwrap(center.requests["noortime.prayer.20261111.dhuhr"])
        XCTAssertEqual(request.content.title, "যোহর")
        XCTAssertTrue(request.content.body.contains("যোহর"))
    }

    func testTriggerIsTheExactPrayerMoment() async throws {
        let center = FakeNotificationCenter()
        _ = await reconcile(makeScheduler(center))
        let request = try XCTUnwrap(center.requests["noortime.prayer.20261111.dhuhr"])
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertFalse(trigger.repeats)
        XCTAssertEqual(NotificationTestHelpers.fireDate(of: request, in: TestSupport.dhaka),
                       TestSupport.date(2026, 11, 11, 12, 0))
    }

    func testTriggerUsesThePlacesTimeZoneNotThePhones() async throws {
        let newYork = TimeZone(identifier: "America/New_York")!
        let place = PrayerLocation(latitude: 40.71, longitude: -74.01, timeZone: newYork)
        let center = FakeNotificationCenter()
        _ = await reconcile(makeScheduler(center),
                            location: place,
                            now: TestSupport.date(2026, 11, 11, 10, 0, in: newYork))

        let request = try XCTUnwrap(center.requests["noortime.prayer.20261111.dhuhr"])
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.dateComponents.timeZone?.identifier, "America/New_York")
        XCTAssertEqual(NotificationTestHelpers.fireDate(of: request, in: newYork),
                       TestSupport.date(2026, 11, 11, 12, 0, in: newYork))
    }

    func testRunningTwiceNeverCreatesDuplicates() async {
        let center = FakeNotificationCenter()
        let scheduler = makeScheduler(center)
        _ = await reconcile(scheduler)
        _ = await reconcile(scheduler)
        _ = await reconcile(scheduler)
        XCTAssertEqual(center.requests.count, 59)
    }

    func testOldOwnRemindersAreRemovedButOtherIdentifiersKept() async {
        let center = FakeNotificationCenter()
        center.seed("other.reminder")
        center.seed("noortime.prayer.20200101.fajr")
        _ = await reconcile(makeScheduler(center))
        XCTAssertNotNil(center.requests["other.reminder"])
        XCTAssertNil(center.requests["noortime.prayer.20200101.fajr"])
    }

    func testCancelAllRemovesOnlyNoorTimeReminders() async {
        let center = FakeNotificationCenter()
        let scheduler = makeScheduler(center)
        _ = await reconcile(scheduler)
        center.seed("other.reminder")
        await scheduler.cancelAll()
        XCTAssertEqual(Set(center.requests.keys), ["other.reminder"])
    }

    func testARejectedReminderIsCountedAndTheRestStillScheduled() async {
        let center = FakeNotificationCenter()
        center.failingIdentifiers = ["noortime.prayer.20261111.asr"]
        let outcome = await reconcile(makeScheduler(center))
        XCTAssertEqual(outcome, .init(scheduled: 58, failed: 1))
        XCTAssertNil(center.requests["noortime.prayer.20261111.asr"])
    }

    func testSwitchedOffPrayerIsNotScheduled() async {
        let center = FakeNotificationCenter()
        var preferences = NotificationPreferences()
        preferences.set(.isha, enabled: false)
        _ = await reconcile(makeScheduler(center), preferences: preferences)
        XCTAssertFalse(center.requests.keys.contains { $0.hasSuffix(".isha") })
    }
}
