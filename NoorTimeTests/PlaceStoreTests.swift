import XCTest
@testable import NoorTime

final class PlaceStoreTests: XCTestCase {

    private func makeDefaults() -> UserDefaults {
        let name = "NoorTimeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testNothingSavedLoadsNil() {
        XCTAssertNil(PlaceStore(defaults: makeDefaults()).load())
    }

    func testSaveThenLoadReturnsSamePlace() {
        let store = PlaceStore(defaults: makeDefaults())
        let place = Place.city(.dhakaFallback, source: .manual)
        store.save(place)
        XCTAssertEqual(store.load(), place)
    }

    func testSavingAgainReplacesThePlace() {
        let store = PlaceStore(defaults: makeDefaults())
        store.save(Place.city(.dhakaFallback, source: .manual))
        let gps = Place.gps(point: GeoPoint(latitude: 22.36, longitude: 91.78), info: .dhaka)
        store.save(gps)
        XCTAssertEqual(store.load(), gps)
    }

    func testCorruptDataLoadsNilInsteadOfCrashing() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: PlaceStore.key)
        XCTAssertNil(PlaceStore(defaults: defaults).load())
    }

    func testLoadOrDefaultFallsBackToDhaka() {
        let place = PlaceStore(defaults: makeDefaults()).loadOrDefault()
        XCTAssertEqual(place.cityID, "dhaka")
        XCTAssertEqual(place.source, .defaultCity)
    }

    func testLoadOrDefaultPrefersSavedPlace() {
        let store = PlaceStore(defaults: makeDefaults())
        let saved = Place.gps(point: GeoPoint(latitude: 22.36, longitude: 91.78), info: .dhaka)
        store.save(saved)
        XCTAssertEqual(store.loadOrDefault(), saved)
    }
}
