import XCTest
@testable import NoorTime

/// Stand-in times (Dhaka): Fajr 05:00, Sunrise 06:15, Dhuhr 12:00, Asr 15:30, Maghrib 18:00, Isha 19:20.
final class PrayerNotificationPlannerTests: XCTestCase {
    private let planner = PrayerNotificationPlanner(calculator: StubCalculator())

    private func plan(at now: Date,
                      preferences: NotificationPreferences = NotificationPreferences(),
                      using planner: PrayerNotificationPlanner? = nil) -> [PlannedNotification] {
        (planner ?? self.planner).plan(now: now,
                                       location: TestSupport.dhakaLocation,
                                       settings: .bangladeshDefault,
                                       preferences: preferences)
    }

    func testMidDayPlanSkipsPastPrayersAndCoversTwelveDays() {
        // 4 prayers left today + 11 full days x 5 = 59
        let result = plan(at: TestSupport.date(2026, 11, 11, 10, 0))
        XCTAssertEqual(result.count, 59)
        XCTAssertEqual(result.first?.prayer, .dhuhr)
        XCTAssertEqual(result.first?.fireDate, TestSupport.date(2026, 11, 11, 12, 0))
    }

    func testNeverSchedulesThePast() {
        let now = TestSupport.date(2026, 11, 11, 10, 0)
        for item in plan(at: now) {
            XCTAssertGreaterThan(item.fireDate, now)
        }
    }

    func testPrayerAtExactlyNowIsNotScheduled() {
        let now = TestSupport.date(2026, 11, 11, 12, 0)   // exactly Dhuhr
        XCTAssertEqual(plan(at: now).first?.prayer, .asr)
    }

    func testSunriseNeverGetsAReminder() {
        XCTAssertFalse(plan(at: TestSupport.date(2026, 11, 11, 0, 30)).contains { $0.prayer == .sunrise })
    }

    func testStaysWithinTheIOSLimitOf64() {
        let result = plan(at: TestSupport.date(2026, 11, 11, 0, 30))
        XCTAssertEqual(result.count, 60)
        XCTAssertLessThanOrEqual(result.count, 64)
    }

    func testIdentifiersAreUniqueAndReadable() {
        let result = plan(at: TestSupport.date(2026, 11, 11, 0, 30))
        XCTAssertEqual(Set(result.map { $0.identifier }).count, result.count)
        XCTAssertTrue(result.contains { $0.identifier == "noortime.prayer.20261111.fajr" })
        XCTAssertTrue(result.allSatisfy { $0.identifier.hasPrefix(PrayerNotificationPlanner.identifierPrefix) })
    }

    func testResultIsSortedByTime() {
        let times = plan(at: TestSupport.date(2026, 11, 11, 0, 30)).map { $0.fireDate }
        XCTAssertEqual(times, times.sorted())
    }

    func testSwitchedOffPrayerIsLeftOut() {
        var preferences = NotificationPreferences()
        preferences.set(.asr, enabled: false)
        let result = plan(at: TestSupport.date(2026, 11, 11, 10, 0), preferences: preferences)
        XCTAssertFalse(result.contains { $0.prayer == .asr })
        XCTAssertEqual(result.count, 47)   // 59 minus 12 Asr reminders
    }

    func testAllPrayersOffGivesEmptyPlan() {
        var preferences = NotificationPreferences()
        for prayer in Prayer.allCases { preferences.set(prayer, enabled: false) }
        XCTAssertTrue(plan(at: TestSupport.date(2026, 11, 11, 10, 0), preferences: preferences).isEmpty)
    }

    func testAfterIshaTodayIsSkippedAndStartsTomorrow() {
        let now = TestSupport.date(2026, 11, 11, 23, 59, 30)
        let result = plan(at: now)
        XCTAssertEqual(result.count, 55)   // 11 full days
        XCTAssertEqual(result.first?.identifier, "noortime.prayer.20261112.fajr")
        XCTAssertEqual(result.first?.fireDate, TestSupport.date(2026, 11, 12, 5, 0))
    }

    func testYearBoundaryIdentifiers() {
        let result = plan(at: TestSupport.date(2026, 12, 30, 10, 0))
        XCTAssertTrue(result.contains { $0.identifier == "noortime.prayer.20261231.isha" })
        XCTAssertTrue(result.contains { $0.identifier == "noortime.prayer.20270101.fajr" })
    }

    func testOneBrokenDayDoesNotBlockTheOthers() {
        let flaky = PrayerNotificationPlanner(calculator: FlakyCalculator(failingDayOfMonth: 13))
        let result = plan(at: TestSupport.date(2026, 11, 11, 10, 0), using: flaky)
        XCTAssertEqual(result.count, 54)   // 59 minus the five prayers of 13 November
        XCTAssertFalse(result.contains { $0.identifier.contains("20261113") })
    }

    func testCalculationFailureGivesEmptyPlan() {
        let broken = PrayerNotificationPlanner(calculator: FailingCalculator())
        XCTAssertTrue(plan(at: Date(), using: broken).isEmpty)
    }

    func testRealCalculationPlanForDhaka() {
        let real = PrayerNotificationPlanner()   // Adhan-based
        let result = plan(at: TestSupport.date(2026, 11, 11, 4, 0), using: real)
        XCTAssertEqual(result.count, 60)
        XCTAssertEqual(result.first?.prayer, .fajr)
        if let first = result.first {
            let minutes = TestSupport.minutesOfDay(first.fireDate)
            XCTAssertTrue((4 * 60 + 30...5 * 60 + 15).contains(minutes), "Fajr minute of day \(minutes)")
        }
    }
}
