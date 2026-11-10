import XCTest
@testable import NoorTime

final class LocalizationTests: XCTestCase {

    private func table(_ language: String) throws -> [String: String] {
        let path = try XCTUnwrap(
            AppBundle.main.path(forResource: "Localizable",
                                ofType: "strings",
                                inDirectory: nil,
                                forLocalization: language),
            "Missing Localizable.strings for \(language)"
        )
        let dictionary = NSDictionary(contentsOfFile: path) as? [String: String]
        return try XCTUnwrap(dictionary)
    }

    func testEnglishAndBengaliHaveExactlyTheSameKeys() throws {
        let english = try table("en")
        let bengali = try table("bn")
        XCTAssertEqual(Set(english.keys), Set(bengali.keys))
    }

    func testNoEmptyTranslations() throws {
        for language in ["en", "bn"] {
            for (key, value) in try table(language) {
                XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty, "\(language): \(key)")
            }
        }
    }

    func testEveryPrayerMethodAndAsrKeyExistsInBothLanguages() throws {
        // Uses the same keys the screens use, so a wrong key in the code is caught here.
        var keys = Prayer.allCases.map { $0.localizationKey }
        keys += CalculationMethodOption.allCases.map { $0.localizationKey }
        keys += AsrSchool.allCases.map { $0.localizationKey }
        for language in ["en", "bn"] {
            let strings = try table(language)
            for key in keys {
                XCTAssertNotNil(strings[key], "\(language) is missing \(key)")
            }
        }
    }

    func testBengaliPrayerNamesAreActuallyBengali() throws {
        let english = try table("en")
        let bengali = try table("bn")
        XCTAssertEqual(bengali["prayer.fajr"], "ফজর")
        XCTAssertEqual(bengali["prayer.isha"], "ইশা")
        for prayer in Prayer.allCases {
            let key = "prayer.\(prayer.rawValue)"
            XCTAssertNotEqual(english[key], bengali[key], key)
        }
    }
}
