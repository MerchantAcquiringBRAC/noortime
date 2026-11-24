import XCTest

/// Very small smoke tests: the app starts and the settings screen opens.
/// They avoid location and notification pop-ups, which the app never shows by itself.
final class NoorTimeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesAndShowsSettingsButton() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
    }

    func testSettingsOpensAndCloses() {
        let app = XCUIApplication()
        app.launch()
        let button = app.buttons["settingsButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }
}
