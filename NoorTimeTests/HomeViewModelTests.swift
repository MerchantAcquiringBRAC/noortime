import XCTest
@testable import NoorTime

@MainActor
final class HomeViewModelTests: XCTestCase {

    private func makeModel(calculator: PrayerTimeCalculating = StubCalculator(),
                           now: Date = TestSupport.date(2026, 11, 11, 10, 0)) -> HomeViewModel {
        HomeViewModel(place: Place.city(.dhakaFallback, source: .defaultCity),
                      settings: .bangladeshDefault,
                      service: PrayerScheduleService(calculator: calculator),
                      now: now)
    }

    func testLoadsScheduleOnInit() {
        let model = makeModel()
        XCTAssertNotNil(model.schedule)
        XCTAssertEqual(model.schedule?.entries.count, 6)
        XCTAssertEqual(model.timeZone.identifier, "Asia/Dhaka")
    }

    func testRefreshAfterMidnightBuildsNewDay() {
        let model = makeModel(now: TestSupport.date(2026, 11, 11, 22, 0))
        let firstDay = model.schedule?.entries.first?.time

        // Same day: nothing changes.
        model.refreshIfNeeded(now: TestSupport.date(2026, 11, 11, 23, 30))
        XCTAssertEqual(model.schedule?.entries.first?.time, firstDay)

        // After midnight: new day.
        model.refreshIfNeeded(now: TestSupport.date(2026, 11, 12, 0, 5))
        XCTAssertEqual(model.schedule?.entries.first?.time, TestSupport.date(2026, 11, 12, 5, 0))
    }

    func testCalculationFailureLeavesNoScheduleInsteadOfFakeData() {
        let model = makeModel(calculator: FailingCalculator(), now: Date())
        XCTAssertNil(model.schedule)
    }

    func testDefaultCityIsDhaka() {
        XCTAssertEqual(CityRepository.defaultCity.id, "dhaka")
    }

    func testChangingPlaceChangesTimeZoneAndRecalculates() {
        let model = makeModel()
        let newYork = TimeZone(identifier: "America/New_York")!
        let place = Place.gps(point: GeoPoint(latitude: 40.71, longitude: -74.01),
                              info: PlaceInfo(nameEn: "New York", nameBn: nil, countryCode: "US", timeZone: newYork))

        let moment = TestSupport.date(2026, 11, 11, 12, 0, in: newYork)
        model.setPlace(place, now: moment)

        XCTAssertEqual(model.timeZone.identifier, "America/New_York")
        XCTAssertEqual(model.schedule?.entries.first?.time,
                       TestSupport.date(2026, 11, 11, 5, 0, in: newYork))
    }

    func testSettingTheSamePlaceDoesNothing() {
        let model = makeModel()
        let before = model.schedule
        model.setPlace(Place.city(.dhakaFallback, source: .defaultCity),
                       now: TestSupport.date(2026, 11, 20, 12, 0))
        XCTAssertEqual(model.schedule, before)
    }

    func testLocationTitleShowsNameAndCountry() {
        let model = makeModel()
        let title = model.locationTitle
        XCTAssertNotNil(title)
        XCTAssertTrue(title?.contains(",") ?? false, "Expected 'City, Country' but got \(title ?? "nil")")
    }

    func testPlaceWithoutNameHasNoTitle() {
        let model = makeModel()
        model.setPlace(Place.gps(point: GeoPoint(latitude: 23.81, longitude: 90.41), info: .empty),
                       now: TestSupport.date(2026, 11, 11, 12, 0))
        XCTAssertNil(model.locationTitle)
    }
}
