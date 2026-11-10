import XCTest
@testable import NoorTime

@MainActor
final class HomeViewModelTests: XCTestCase {

    func testLoadsScheduleOnInit() {
        let now = TestSupport.date(2026, 11, 11, 10, 0)
        let model = HomeViewModel(city: .dhakaFallback,
                                  settings: .bangladeshDefault,
                                  service: PrayerScheduleService(calculator: StubCalculator()),
                                  now: now)
        XCTAssertNotNil(model.schedule)
        XCTAssertEqual(model.schedule?.entries.count, 6)
        XCTAssertEqual(model.timeZone.identifier, "Asia/Dhaka")
    }

    func testRefreshAfterMidnightBuildsNewDay() {
        let evening = TestSupport.date(2026, 11, 11, 22, 0)
        let model = HomeViewModel(city: .dhakaFallback,
                                  settings: .bangladeshDefault,
                                  service: PrayerScheduleService(calculator: StubCalculator()),
                                  now: evening)
        let firstDay = model.schedule?.entries.first?.time

        // Same day: nothing changes.
        model.refreshIfNeeded(now: TestSupport.date(2026, 11, 11, 23, 30))
        XCTAssertEqual(model.schedule?.entries.first?.time, firstDay)

        // After midnight: new day.
        model.refreshIfNeeded(now: TestSupport.date(2026, 11, 12, 0, 5))
        XCTAssertEqual(model.schedule?.entries.first?.time, TestSupport.date(2026, 11, 12, 5, 0))
    }

    func testCalculationFailureLeavesNoScheduleInsteadOfFakeData() {
        let model = HomeViewModel(city: .dhakaFallback,
                                  settings: .bangladeshDefault,
                                  service: PrayerScheduleService(calculator: FailingCalculator()),
                                  now: Date())
        XCTAssertNil(model.schedule)
    }

    func testDefaultCityIsDhaka() {
        XCTAssertEqual(CityRepository.defaultCity.id, "dhaka")
    }
}
