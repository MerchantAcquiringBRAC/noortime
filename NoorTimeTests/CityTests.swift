import XCTest
@testable import NoorTime

final class CityTests: XCTestCase {

    func testCitiesFileLoads() throws {
        let cities = try CityRepository.loadCities()
        XCTAssertGreaterThanOrEqual(cities.count, 6)
    }

    func testRequiredBangladeshCitiesExist() throws {
        let ids = Set(try CityRepository.loadCities().map { $0.id })
        for required in ["dhaka", "chattogram", "sylhet", "rajshahi", "khulna", "barishal"] {
            XCTAssertTrue(ids.contains(required), "Missing city: \(required)")
        }
    }

    func testIdsAreUniqueAndNamesPresent() throws {
        let cities = try CityRepository.loadCities()
        XCTAssertEqual(Set(cities.map { $0.id }).count, cities.count)
        for city in cities {
            XCTAssertFalse(city.nameEn.isEmpty)
            XCTAssertFalse(city.nameBn.isEmpty)
        }
    }

    func testEveryCityHasValidTimeZoneAndCoordinates() throws {
        for city in try CityRepository.loadCities() {
            XCTAssertNotNil(TimeZone(identifier: city.timeZoneIdentifier), city.id)
            XCTAssertTrue((-90.0...90.0).contains(city.latitude), city.id)
            XCTAssertTrue((-180.0...180.0).contains(city.longitude), city.id)
            if city.countryCode == "BD" {
                XCTAssertTrue((20.5...26.7).contains(city.latitude), city.id)
                XCTAssertTrue((88.0...92.7).contains(city.longitude), city.id)
                XCTAssertEqual(city.timeZoneIdentifier, "Asia/Dhaka", city.id)
            }
        }
    }

    func testDisplayNameFollowsLanguage() {
        XCTAssertEqual(City.dhakaFallback.displayName(languageCode: "en"), "Dhaka")
        XCTAssertEqual(City.dhakaFallback.displayName(languageCode: "bn"), "ঢাকা")
    }

    func testCityLocationUsesCityTimeZone() {
        XCTAssertEqual(City.dhakaFallback.location.timeZone.identifier, "Asia/Dhaka")
    }
}
