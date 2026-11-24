import XCTest
@testable import NoorTime

@MainActor
final class LocationControllerTests: XCTestCase {

    private func makeStore() -> PlaceStore {
        let name = "NoorTimeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return PlaceStore(defaults: defaults)
    }

    private func makeController(provider: FakeLocationProvider,
                                info: PlaceInfo = .dhaka,
                                store: PlaceStore) -> LocationController {
        LocationController(provider: provider,
                           resolver: FakeResolver(info: info),
                           store: store,
                           cities: nil)
    }

    private func city(_ id: String) throws -> City {
        let all = try CityRepository.loadCities()
        return try XCTUnwrap(all.first { $0.id == id })
    }

    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testStartsWithDefaultDhakaWhenNothingSaved() {
        let controller = makeController(provider: FakeLocationProvider(), store: makeStore())
        XCTAssertEqual(controller.place.cityID, "dhaka")
        XCTAssertEqual(controller.place.source, .defaultCity)
        XCTAssertEqual(controller.requestState, .idle)
    }

    func testUseCurrentLocationSavesRoundedGPSPlace() async {
        let store = makeStore()
        let controller = makeController(provider: FakeLocationProvider(), store: store)

        await controller.useCurrentLocation(now: start)

        XCTAssertEqual(controller.requestState, .idle)
        XCTAssertEqual(controller.place.source, .gps)
        XCTAssertEqual(controller.place.latitude, 23.81, accuracy: 0.0000001)
        XCTAssertEqual(controller.place.longitude, 90.41, accuracy: 0.0000001)
        XCTAssertEqual(controller.place.displayName(languageCode: "en"), "Dhaka")
        XCTAssertEqual(controller.place.timeZoneIdentifier, "Asia/Dhaka")
        XCTAssertEqual(store.load(), controller.place)
    }

    func testPermissionDeniedKeepsPreviousPlaceAndShowsError() async {
        let store = makeStore()
        let provider = FakeLocationProvider()
        provider.result = .failure(.permissionDenied)
        let controller = makeController(provider: provider, store: store)
        let before = controller.place

        await controller.useCurrentLocation(now: start)

        XCTAssertEqual(controller.requestState, .failed(.permissionDenied))
        XCTAssertEqual(controller.place, before)
        XCTAssertNil(store.load())
    }

    func testTimeoutIsReportedToTheUser() async {
        let provider = FakeLocationProvider()
        provider.result = .failure(.timeout)
        let controller = makeController(provider: provider, store: makeStore())

        await controller.useCurrentLocation(now: start)

        XCTAssertEqual(controller.requestState, .failed(.timeout))
    }

    func testSelectingCitySavesManualPlace() throws {
        let store = makeStore()
        let controller = makeController(provider: FakeLocationProvider(), store: store)

        controller.select(city: try city("sylhet"))

        XCTAssertEqual(controller.place.source, .manual)
        XCTAssertEqual(controller.place.cityID, "sylhet")
        XCTAssertEqual(store.load()?.cityID, "sylhet")
        XCTAssertEqual(controller.requestState, .idle)
    }

    func testChoosingDhakaManuallyOverridesTheDefaultLabel() throws {
        let controller = makeController(provider: FakeLocationProvider(), store: makeStore())
        controller.select(city: try city("dhaka"))
        XCTAssertEqual(controller.place.source, .manual)
    }

    func testGeocodingFailureStillGivesAWorkingPlace() async {
        let controller = makeController(provider: FakeLocationProvider(), info: .empty, store: makeStore())

        await controller.useCurrentLocation(now: start)

        XCTAssertEqual(controller.place.source, .gps)
        XCTAssertNil(controller.place.displayName(languageCode: "en"))
        XCTAssertEqual(controller.place.timeZoneIdentifier, TimeZone.current.identifier)
    }

    func testCityPickedWhileGPSIsBusyIsNotOverwritten() async throws {
        let store = makeStore()
        let provider = FakeLocationProvider()
        let controller = makeController(provider: provider, store: store)
        let sylhet = try city("sylhet")

        // While GPS is working, the user picks Sylhet.
        provider.onCall = { controller.select(city: sylhet) }
        await controller.useCurrentLocation(now: start)

        XCTAssertEqual(controller.place.cityID, "sylhet")
        XCTAssertEqual(controller.place.source, .manual)
        XCTAssertEqual(store.load()?.cityID, "sylhet")
        XCTAssertEqual(controller.requestState, .idle)
    }

    func testFailedSilentRefreshIsAlsoThrottled() async {
        let provider = FakeLocationProvider()
        let controller = makeController(provider: provider, store: makeStore())
        await controller.useCurrentLocation(now: start)
        XCTAssertEqual(provider.callCount, 1)

        provider.result = .failure(.unavailable)
        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(31 * 60))   // tries, fails
        XCTAssertEqual(provider.callCount, 2)

        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(40 * 60))   // too soon after the failed try
        XCTAssertEqual(provider.callCount, 2)

        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(62 * 60))   // long enough: tries again
        XCTAssertEqual(provider.callCount, 3)
    }

    func testSavedPlaceIsRestoredOnNextLaunch() throws {
        let store = makeStore()
        let first = makeController(provider: FakeLocationProvider(), store: store)
        first.select(city: try city("khulna"))

        let second = makeController(provider: FakeLocationProvider(), store: store)
        XCTAssertEqual(second.place, first.place)
    }

    func testAutomaticRefreshDoesNothingForNonGPSPlace() async {
        let provider = FakeLocationProvider()
        let controller = makeController(provider: provider, store: makeStore())

        await controller.refreshGPSIfNeeded(now: start)

        XCTAssertEqual(provider.callCount, 0)
    }

    func testAutomaticRefreshUpdatesGPSPlaceButOnlyEvery30Minutes() async {
        let provider = FakeLocationProvider()
        let controller = makeController(provider: provider, store: makeStore())
        await controller.useCurrentLocation(now: start)
        XCTAssertEqual(provider.callCount, 1)

        // The phone moves to Chattogram.
        provider.result = .success(GeoPoint(latitude: 22.3569, longitude: 91.7832))

        // 10 minutes later: too soon, no GPS request.
        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(10 * 60))
        XCTAssertEqual(provider.callCount, 1)
        XCTAssertEqual(controller.place.latitude, 23.81, accuracy: 0.0000001)

        // 31 minutes later: refreshed.
        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(31 * 60))
        XCTAssertEqual(provider.callCount, 2)
        XCTAssertEqual(controller.place.latitude, 22.36, accuracy: 0.0000001)
        XCTAssertEqual(controller.place.longitude, 91.78, accuracy: 0.0000001)
    }

    func testAutomaticRefreshFailureIsSilent() async {
        let provider = FakeLocationProvider()
        let controller = makeController(provider: provider, store: makeStore())
        await controller.useCurrentLocation(now: start)
        let before = controller.place

        provider.result = .failure(.unavailable)
        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(60 * 60))

        XCTAssertEqual(controller.requestState, .idle)
        XCTAssertEqual(controller.place, before)
    }

    func testAutomaticRefreshNeverRunsWithoutPermission() async {
        let provider = FakeLocationProvider()
        let controller = makeController(provider: provider, store: makeStore())
        await controller.useCurrentLocation(now: start)
        XCTAssertEqual(provider.callCount, 1)

        provider.authorization = .denied
        controller.refreshAuthorization()
        await controller.refreshGPSIfNeeded(now: start.addingTimeInterval(2 * 60 * 60))

        XCTAssertEqual(provider.callCount, 1)
    }
}
