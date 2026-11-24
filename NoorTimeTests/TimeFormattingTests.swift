import XCTest
@testable import NoorTime

final class TimeFormattingTests: XCTestCase {

    func testCountdownFormatting() {
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 0), "00:00:00")
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 59), "00:00:59")
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 3600), "01:00:00")
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 9669), "02:41:09")
    }

    /// Newer iOS versions put a narrow no-break space before AM/PM; treat all such spaces as a normal space.
    private func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    func testBengaliDigits() {
        XCTAssertEqual(TimeFormatting.localizedDigits("02:41:09", languageCode: "bn"), "০২:৪১:০৯")
        XCTAssertEqual(TimeFormatting.localizedDigits("02:41:09", languageCode: "en"), "02:41:09")
        XCTAssertEqual(TimeFormatting.localizedDigits("abc 1", languageCode: "bn"), "abc ১")
    }

    func testClockStringFollowsTheGivenLocale() {
        let moment = TestSupport.date(2026, 11, 11, 16, 55)
        let english = TimeFormatting.clockString(moment, timeZone: TestSupport.dhaka, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(plain(english), "4:55 PM")

        let bengali = TimeFormatting.clockString(moment, timeZone: TestSupport.dhaka, locale: Locale(identifier: "bn"))
        let bengaliDigits = "০১২৩৪৫৬৭৮৯"
        XCTAssertTrue(bengali.contains { bengaliDigits.contains($0) }, "Expected Bengali digits in \(bengali)")
    }

    func testClockStringUsesThePlacesTimeZone() {
        let moment = TestSupport.date(2026, 11, 11, 16, 55)   // Dhaka
        let newYork = TimeZone(identifier: "America/New_York")!
        let text = TimeFormatting.clockString(moment, timeZone: newYork, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(plain(text), "5:55 AM")
    }

    func testCountdownNeverGoesNegative() {
        XCTAssertEqual(TimeFormatting.countdownString(seconds: -5), "00:00:00")
    }

    func testCountdownDropsFractionsRatherThanRoundingUp() {
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 59.9), "00:00:59")
    }
}
