import XCTest
@testable import NoorTime

final class TimeFormattingTests: XCTestCase {

    func testCountdownFormatting() {
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 0), "00:00:00")
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 59), "00:00:59")
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 3600), "01:00:00")
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 9669), "02:41:09")
    }

    func testCountdownNeverGoesNegative() {
        XCTAssertEqual(TimeFormatting.countdownString(seconds: -5), "00:00:00")
    }

    func testCountdownDropsFractionsRatherThanRoundingUp() {
        XCTAssertEqual(TimeFormatting.countdownString(seconds: 59.9), "00:00:59")
    }
}
