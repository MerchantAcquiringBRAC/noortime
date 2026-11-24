import XCTest
import AVFoundation
@testable import NoorTime

final class NotificationPreferencesTests: XCTestCase {

    func testEveryPrayerIsOnByDefault() {
        let preferences = NotificationPreferences()
        for prayer in Prayer.allCases where prayer.isPrayer {
            XCTAssertTrue(preferences.isEnabled(prayer), "\(prayer)")
        }
    }

    func testSunriseIsNeverEnabled() {
        var preferences = NotificationPreferences()
        preferences.set(.sunrise, enabled: true)
        XCTAssertFalse(preferences.isEnabled(.sunrise))
    }

    func testSwitchingOffAndOn() {
        var preferences = NotificationPreferences()
        preferences.set(.fajr, enabled: false)
        XCTAssertFalse(preferences.isEnabled(.fajr))
        XCTAssertTrue(preferences.isEnabled(.dhuhr))
        preferences.set(.fajr, enabled: true)
        XCTAssertTrue(preferences.isEnabled(.fajr))
        XCTAssertEqual(preferences, NotificationPreferences())
    }

    func testStoreRoundTrip() {
        let store = NotificationTestHelpers.makeStore()
        XCTAssertEqual(store.load(), NotificationPreferences())   // nothing saved: all on

        var preferences = NotificationPreferences()
        preferences.set(.isha, enabled: false)
        store.save(preferences)
        XCTAssertEqual(store.load(), preferences)
    }

    func testCorruptSavedDataFallsBackToAllOn() {
        let name = "NoorTimeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        defaults.set(Data("garbage".utf8), forKey: NotificationPreferencesStore.key)
        XCTAssertEqual(NotificationPreferencesStore(defaults: defaults).load(), NotificationPreferences())
    }

    func testStatusMapsFromIOSAuthorization() {
        XCTAssertEqual(NotificationStatus(.notDetermined), .notSetUp)
        XCTAssertEqual(NotificationStatus(.authorized), .enabled)
        XCTAssertEqual(NotificationStatus(.denied), .denied)
    }
}

final class NotificationSoundTests: XCTestCase {

    func testSoundFileIsBundledAndShorterThanThirtySeconds() throws {
        let url = try XCTUnwrap(NotificationSound.url, "adhan_short.wav is missing from the app")
        let player = try AVAudioPlayer(contentsOf: url)
        XCTAssertGreaterThan(player.duration, 1)
        XCTAssertLessThan(player.duration, NotificationSound.maximumSeconds)
    }

    func testFileNameMatchesWhatTheReminderUses() {
        XCTAssertEqual(NotificationSound.fileName, "adhan_short.wav")
    }
}
