import XCTest
@testable import NoorTime

final class PlaceTests: XCTestCase {

    func testCoordinatesAreRoundedToTwoDecimals() {
        let rounded = GeoPoint(latitude: 23.81234, longitude: 90.41678).rounded
        XCTAssertEqual(rounded.latitude, 23.81, accuracy: 0.0000001)
        XCTAssertEqual(rounded.longitude, 90.42, accuracy: 0.0000001)
    }

    func testNegativeCoordinatesRoundCorrectly() {
        let rounded = GeoPoint(latitude: -33.8688, longitude: -70.5).rounded
        XCTAssertEqual(rounded.latitude, -33.87, accuracy: 0.0000001)
        XCTAssertEqual(rounded.longitude, -70.5, accuracy: 0.0000001)
    }

    func testGPSPlaceUsesRoundedCoordinatesAndGeocodedInfo() {
        let place = Place.gps(point: GeoPoint(latitude: 23.81034, longitude: 90.41256), info: .dhaka)
        XCTAssertEqual(place.source, .gps)
        XCTAssertNil(place.cityID)
        XCTAssertEqual(place.latitude, 23.81, accuracy: 0.0000001)
        XCTAssertEqual(place.longitude, 90.41, accuracy: 0.0000001)
        XCTAssertEqual(place.timeZoneIdentifier, "Asia/Dhaka")
        XCTAssertEqual(place.countryCode, "BD")
    }

    func testDisplayNameFollowsLanguageWithFallbacks() {
        let both = Place.gps(point: GeoPoint(latitude: 23.81, longitude: 90.41), info: .dhaka)
        XCTAssertEqual(both.displayName(languageCode: "en"), "Dhaka")
        XCTAssertEqual(both.displayName(languageCode: "bn"), "ঢাকা")

        let onlyEnglish = Place.gps(point: GeoPoint(latitude: 1, longitude: 1),
                                    info: PlaceInfo(nameEn: "Somewhere", nameBn: nil, countryCode: nil, timeZone: nil))
        XCTAssertEqual(onlyEnglish.displayName(languageCode: "bn"), "Somewhere")

        let none = Place.gps(point: GeoPoint(latitude: 1, longitude: 1), info: .empty)
        XCTAssertNil(none.displayName(languageCode: "en"))
    }

    func testCountryNameIsFilledInEnglish() {
        let place = Place.city(.dhakaFallback, source: .manual)
        XCTAssertEqual(place.countryName(languageCode: "en"), "Bangladesh")
        XCTAssertFalse(place.countryName(languageCode: "bn")?.isEmpty ?? true)
    }

    func testCityPlaceCopiesCityDetails() {
        let place = Place.city(.dhakaFallback, source: .manual)
        XCTAssertEqual(place.source, .manual)
        XCTAssertEqual(place.cityID, "dhaka")
        XCTAssertEqual(place.latitude, City.dhakaFallback.latitude)
        XCTAssertEqual(place.location.timeZone.identifier, "Asia/Dhaka")
    }

    func testTimeZoneFallbackUsesThePhoneZone() {
        // Dhaka-area point and a Kolkata point: both use the phone's zone, never a guessed one.
        for point in [GeoPoint(latitude: 24.89, longitude: 91.87), GeoPoint(latitude: 22.57, longitude: 88.36)] {
            XCTAssertEqual(TimeZoneFallback.zone(for: point).identifier, TimeZone.current.identifier)
        }
    }

    func testGPSPlaceWithoutGeocodedZoneUsesPhoneZone() {
        let place = Place.gps(point: GeoPoint(latitude: 22.36, longitude: 91.78), info: .empty)
        XCTAssertEqual(place.timeZoneIdentifier, TimeZone.current.identifier)
    }

    func testGeocodedTimeZoneWinsOverTheFallback() {
        let newYork = TimeZone(identifier: "America/New_York")!
        let place = Place.gps(point: GeoPoint(latitude: 40.71, longitude: -74.01),
                              info: PlaceInfo(nameEn: nil, nameBn: nil, countryCode: nil, timeZone: newYork))
        XCTAssertEqual(place.timeZoneIdentifier, "America/New_York")
    }

    func testPlaceSurvivesEncodingAndDecoding() throws {
        let original = Place.gps(point: GeoPoint(latitude: 23.81, longitude: 90.41), info: .dhaka)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Place.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
