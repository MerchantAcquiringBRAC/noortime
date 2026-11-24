import XCTest
import UserNotifications
@testable import NoorTime

@MainActor
final class NotificationControllerTests: XCTestCase {
    private let now = TestSupport.date(2026, 11, 11, 10, 0)
    private let settings = PrayerCalculationSettings.bangladeshDefault

    private func makeController(center: FakeNotificationCenter,
                                store: NotificationPreferencesStore? = nil,
                                language: String = "en") -> NotificationController {
        NotificationController(center: center,
                               planner: PrayerNotificationPlanner(calculator: StubCalculator()),
                               store: store ?? NotificationTestHelpers.makeStore(),
                               language: { language })
    }

    func testNothingIsScheduledAndNoPopupBeforeThePermissionIsAsked() async {
        let center = FakeNotificationCenter(authorization: .notDetermined)
        let controller = makeController(center: center)

        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)

        XCTAssertEqual(controller.status, .notSetUp)
        XCTAssertTrue(center.requests.isEmpty)
        XCTAssertEqual(center.permissionPromptCount, 0)
    }

    func testAllowingPermissionSchedulesReminders() async {
        let center = FakeNotificationCenter(authorization: .notDetermined, userAllowsWhenAsked: true)
        let controller = makeController(center: center)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)

        await controller.requestPermission(now: now)

        XCTAssertEqual(controller.status, .enabled)
        XCTAssertEqual(center.permissionPromptCount, 1)
        XCTAssertEqual(center.requests.count, 59)
    }

    func testDenyingPermissionSchedulesNothing() async {
        let center = FakeNotificationCenter(authorization: .notDetermined, userAllowsWhenAsked: false)
        let controller = makeController(center: center)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)

        await controller.requestPermission(now: now)

        XCTAssertEqual(controller.status, .denied)
        XCTAssertTrue(center.requests.isEmpty)
    }

    func testAskingAgainAfterAnswerDoesNotShowAnotherPopup() async {
        let center = FakeNotificationCenter(authorization: .notDetermined, userAllowsWhenAsked: true)
        let controller = makeController(center: center)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)
        await controller.requestPermission(now: now)
        await controller.requestPermission(now: now)
        XCTAssertEqual(center.permissionPromptCount, 1)
    }

    func testSwitchingAPrayerOffRemovesItsRemindersAndIsRemembered() async {
        let center = FakeNotificationCenter()
        let store = NotificationTestHelpers.makeStore()
        let controller = makeController(center: center, store: store)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)
        XCTAssertEqual(center.requests.count, 59)

        await controller.setEnabled(.asr, false, now: now)

        XCTAssertEqual(center.requests.count, 47)
        XCTAssertFalse(center.requests.keys.contains { $0.hasSuffix(".asr") })

        // A fresh controller (next app launch) remembers the choice.
        let relaunched = makeController(center: FakeNotificationCenter(), store: store)
        XCTAssertFalse(relaunched.preferences.isEnabled(.asr))
        XCTAssertTrue(relaunched.preferences.isEnabled(.fajr))
    }

    func testSwitchingAPrayerBackOnRestoresItsReminders() async {
        let center = FakeNotificationCenter()
        let controller = makeController(center: center)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)
        await controller.setEnabled(.asr, false, now: now)
        await controller.setEnabled(.asr, true, now: now)
        XCTAssertEqual(center.requests.count, 59)
    }

    func testChangingPlaceReplacesTheReminders() async {
        let center = FakeNotificationCenter()
        let controller = makeController(center: center)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)

        let newYork = TimeZone(identifier: "America/New_York")!
        let newYorkPlace = PrayerLocation(latitude: 40.71, longitude: -74.01, timeZone: newYork)
        await controller.sync(location: newYorkPlace, settings: settings, now: now)

        // 10:00 in Dhaka is 23:00 the evening before in New York, so that day is already over.
        XCTAssertEqual(center.requests.count, 55)
        for request in center.requests.values {
            let trigger = request.trigger as? UNCalendarNotificationTrigger
            XCTAssertEqual(trigger?.dateComponents.timeZone?.identifier, "America/New_York")
        }
    }

    func testRevokedPermissionClearsPendingReminders() async {
        let center = FakeNotificationCenter()
        let controller = makeController(center: center)
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)
        XCTAssertEqual(center.requests.count, 59)

        center.authorizationState = .denied
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)

        XCTAssertEqual(controller.status, .denied)
        XCTAssertTrue(center.requests.isEmpty)
    }

    func testTwoSyncsAtTheSameTimeNeverDuplicate() async {
        let center = FakeNotificationCenter()
        let controller = makeController(center: center)
        let location = TestSupport.dhakaLocation

        async let first: Void = controller.sync(location: location, settings: settings, now: now)
        async let second: Void = controller.sync(location: location, settings: settings, now: now)
        await first
        await second

        XCTAssertEqual(center.requests.count, 59)
    }

    func testReminderTextFollowsTheAppLanguage() async throws {
        let center = FakeNotificationCenter()
        let controller = makeController(center: center, language: "bn")
        await controller.sync(location: TestSupport.dhakaLocation, settings: settings, now: now)
        let request = try XCTUnwrap(center.requests["noortime.prayer.20261111.maghrib"])
        XCTAssertEqual(request.content.title, "মাগরিব")
    }
}
