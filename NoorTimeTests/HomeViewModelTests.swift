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

    func testChangingAsrSchoolRecalculatesTheSchedule() throws {
        // Uses the real calculation (no stand-in) so Hanafi and Shafi Asr really differ.
        let now = TestSupport.date(2026, 11, 11, 10, 0)
        let model = HomeViewModel(place: Place.city(.dhakaFallback, source: .defaultCity),
                                  settings: .bangladeshDefault,
                                  service: PrayerScheduleService(),
                                  now: now)
        let hanafiAsr = try XCTUnwrap(model.schedule?.entries.first { $0.prayer == .asr }?.time)

        var shafi = PrayerCalculationSettings.bangladeshDefault
        shafi.asrSchool = .shafi
        model.setSettings(shafi, now: now)

        let shafiAsr = try XCTUnwrap(model.schedule?.entries.first { $0.prayer == .asr }?.time)
        XCTAssertLessThan(shafiAsr, hanafiAsr)
        XCTAssertEqual(model.settings.asrSchool, .shafi)
    }

    func testAdjustmentChangesTheDisplayedTime() throws {
        let model = makeModel()   // stand-in times, no adjustments in the stand-in itself
        var settings = PrayerCalculationSettings.bangladeshDefault
        settings.adjustments.set(3, for: .fajr)
        let adjustedModel = HomeViewModel(place: Place.city(.dhakaFallback, source: .defaultCity),
                                          settings: settings,
                                          service: PrayerScheduleService(calculator: AdjustedPrayerTimeCalculator(base: StubCalculator())),
                                          now: TestSupport.date(2026, 11, 11, 3, 0))
        XCTAssertEqual(model.schedule?.entries.first?.time, TestSupport.date(2026, 11, 11, 5, 0))
        XCTAssertEqual(adjustedModel.schedule?.entries.first?.time, TestSupport.date(2026, 11, 11, 5, 3))
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
