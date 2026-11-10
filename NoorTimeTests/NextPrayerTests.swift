import XCTest
@testable import NoorTime

/// Uses fixed stand-in times (Fajr 05:00, Sunrise 06:15, Dhuhr 12:00,
/// Asr 15:30, Maghrib 18:00, Isha 19:20) so every answer is exact.
final class NextPrayerTests: XCTestCase {
    private let service = PrayerScheduleService(calculator: StubCalculator())

    private func schedule(at moment: Date) throws -> DailyPrayerSchedule {
        try service.schedule(for: moment,
                             location: TestSupport.dhakaLocation,
                             settings: .bangladeshDefault)
    }

    func testBeforeFajrNextIsFajr() throws {
        let now = TestSupport.date(2026, 11, 11, 3, 0)
        let next = try schedule(at: now).next(after: now)
        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertEqual(next.time, TestSupport.date(2026, 11, 11, 5, 0))
    }

    func testSunriseIsNeverTheNextPrayer() throws {
        let now = TestSupport.date(2026, 11, 11, 5, 30)   // between Fajr and Sunrise
        XCTAssertEqual(try schedule(at: now).next(after: now).prayer, .dhuhr)

        let later = TestSupport.date(2026, 11, 11, 6, 30)  // after Sunrise
        XCTAssertEqual(try schedule(at: later).next(after: later).prayer, .dhuhr)
    }

    func testExactlyAtPrayerTimeMovesToFollowingPrayer() throws {
        let atDhuhr = TestSupport.date(2026, 11, 11, 12, 0)
        XCTAssertEqual(try schedule(at: atDhuhr).next(after: atDhuhr).prayer, .asr)
    }

    func testOneSecondBeforePrayerStillCountsDown() throws {
        let now = TestSupport.date(2026, 11, 11, 11, 59, 59)
        let next = try schedule(at: now).next(after: now)
        XCTAssertEqual(next.prayer, .dhuhr)
        XCTAssertEqual(next.time.timeIntervalSince(now), 1, accuracy: 0.001)
    }

    func testAfterIshaNextIsTomorrowsFajr() throws {
        let now = TestSupport.date(2026, 11, 11, 21, 0)
        let next = try schedule(at: now).next(after: now)
        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertEqual(next.time, TestSupport.date(2026, 11, 12, 5, 0))
    }

    func testJustBeforeMidnightNextIsTomorrowsFajr() throws {
        let now = TestSupport.date(2026, 11, 11, 23, 59, 59)
        let next = try schedule(at: now).next(after: now)
        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertEqual(next.time, TestSupport.date(2026, 11, 12, 5, 0))
    }

    func testJustAfterMidnightNextIsTodaysFajr() throws {
        let now = TestSupport.date(2026, 11, 12, 0, 0, 1)
        let current = try schedule(at: now)
        XCTAssertEqual(current.next(after: now).time, TestSupport.date(2026, 11, 12, 5, 0))
        XCTAssertEqual(current.entries.first?.time, TestSupport.date(2026, 11, 12, 5, 0))
    }

    func testScheduleKnowsWhenTheDayHasChanged() throws {
        let evening = TestSupport.date(2026, 11, 11, 20, 0)
        let current = try schedule(at: evening)
        let tz = TestSupport.dhaka
        XCTAssertTrue(current.isCurrent(at: TestSupport.date(2026, 11, 11, 23, 59, 59), timeZone: tz))
        XCTAssertFalse(current.isCurrent(at: TestSupport.date(2026, 11, 12, 0, 0, 0), timeZone: tz))
    }

    func testMonthAndYearBoundary() throws {
        let now = TestSupport.date(2026, 12, 31, 22, 0)
        let next = try schedule(at: now).next(after: now)
        XCTAssertEqual(next.time, TestSupport.date(2027, 1, 1, 5, 0))
    }

    func testRealCalculationAcrossMidnight() throws {
        let real = PrayerScheduleService()   // Adhan-based
        let before = TestSupport.date(2026, 11, 11, 23, 59, 59)
        let schedule = try real.schedule(for: before,
                                         location: TestSupport.dhakaLocation,
                                         settings: .bangladeshDefault)
        let next = schedule.next(after: before)
        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertEqual(TestSupport.localDay(next.time).day, 12)
    }

    func testFailureIsReportedNotHidden() {
        let failing = PrayerScheduleService(calculator: FailingCalculator())
        XCTAssertThrowsError(try failing.schedule(for: Date(),
                                                  location: TestSupport.dhakaLocation,
                                                  settings: .bangladeshDefault))
    }
}
