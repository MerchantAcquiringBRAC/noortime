import XCTest
import SwiftUI
@testable import NoorTime

// MARK: - Helpers

private func makeDefaults() -> UserDefaults {
    let name = "NoorTimeTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

// MARK: - Model and storage

final class AppSettingsModelTests: XCTestCase {

    func testDefaultsAreBangladeshFirst() {
        let settings = AppSettings()
        XCTAssertEqual(settings.language, .system)
        XCTAssertEqual(settings.theme, .system)
        XCTAssertEqual(settings.calculation.method, .karachi)
        XCTAssertEqual(settings.calculation.asrSchool, .hanafi)
        XCTAssertTrue(settings.calculation.adjustments.isZero)
    }

    func testStoreRoundTripKeepsEverything() {
        let store = AppSettingsStore(defaults: makeDefaults())
        var settings = AppSettings()
        settings.language = .bengali
        settings.theme = .dark
        settings.calculation.method = .muslimWorldLeague
        settings.calculation.asrSchool = .shafi
        settings.calculation.adjustments.set(4, for: .fajr)
        settings.calculation.adjustments.set(-2, for: .isha)
        store.save(settings)
        XCTAssertEqual(store.load(), settings)
    }

    func testNothingSavedGivesDefaults() {
        XCTAssertEqual(AppSettingsStore(defaults: makeDefaults()).load(), AppSettings())
    }

    func testCorruptSavedDataGivesDefaults() {
        let defaults = makeDefaults()
        defaults.set(Data("garbage".utf8), forKey: AppSettingsStore.key)
        XCTAssertEqual(AppSettingsStore(defaults: defaults).load(), AppSettings())
    }

    func testLanguageAndThemeChoices() {
        XCTAssertNil(LanguageChoice.system.code)
        XCTAssertEqual(LanguageChoice.english.code, "en")
        XCTAssertEqual(LanguageChoice.bengali.code, "bn")
        XCTAssertNil(ThemeChoice.system.colorScheme)
        XCTAssertEqual(ThemeChoice.light.colorScheme, .light)
        XCTAssertEqual(ThemeChoice.dark.colorScheme, .dark)
    }
}

// MARK: - Manual adjustments

final class PrayerAdjustmentsTests: XCTestCase {

    func testStartsAtZero() {
        let adjustments = PrayerAdjustments()
        XCTAssertTrue(adjustments.isZero)
        for prayer in Prayer.allCases {
            XCTAssertEqual(adjustments.minutes(for: prayer), 0)
        }
    }

    func testSetAndReadBack() {
        var adjustments = PrayerAdjustments()
        adjustments.set(5, for: .dhuhr)
        adjustments.set(-3, for: .asr)
        XCTAssertEqual(adjustments.minutes(for: .dhuhr), 5)
        XCTAssertEqual(adjustments.minutes(for: .asr), -3)
        XCTAssertEqual(adjustments.minutes(for: .fajr), 0)
        XCTAssertFalse(adjustments.isZero)
    }

    func testValuesAreLimitedToThirtyMinutes() {
        var adjustments = PrayerAdjustments()
        adjustments.set(99, for: .fajr)
        adjustments.set(-99, for: .isha)
        XCTAssertEqual(adjustments.minutes(for: .fajr), 30)
        XCTAssertEqual(adjustments.minutes(for: .isha), -30)
    }

    func testSettingZeroEqualsNeverHavingChangedAnything() {
        var adjustments = PrayerAdjustments()
        adjustments.set(7, for: .maghrib)
        adjustments.set(0, for: .maghrib)
        XCTAssertEqual(adjustments, PrayerAdjustments())
    }

    func testReset() {
        var adjustments = PrayerAdjustments()
        adjustments.set(7, for: .maghrib)
        adjustments.set(-1, for: .fajr)
        adjustments.reset()
        XCTAssertTrue(adjustments.isZero)
    }
}

// MARK: - Applying adjustments to calculated times

final class AdjustedCalculatorTests: XCTestCase {
    private let day = TestSupport.date(2026, 11, 11, 10, 0)
    private let calculator = AdjustedPrayerTimeCalculator(base: StubCalculator())

    private func entries(_ settings: PrayerCalculationSettings) throws -> [Prayer: Date] {
        let list = try calculator.entries(for: day, location: TestSupport.dhakaLocation, settings: settings)
        return Dictionary(uniqueKeysWithValues: list.map { ($0.prayer, $0.time) })
    }

    func testZeroAdjustmentsChangeNothing() throws {
        let times = try entries(.bangladeshDefault)
        XCTAssertEqual(times[.fajr], TestSupport.date(2026, 11, 11, 5, 0))
        XCTAssertEqual(times[.asr], TestSupport.date(2026, 11, 11, 15, 30))
    }

    func testAdjustmentsMovePrayersByTheRightMinutes() throws {
        var settings = PrayerCalculationSettings.bangladeshDefault
        settings.adjustments.set(2, for: .fajr)
        settings.adjustments.set(-3, for: .asr)
        let times = try entries(settings)
        XCTAssertEqual(times[.fajr], TestSupport.date(2026, 11, 11, 5, 2))
        XCTAssertEqual(times[.asr], TestSupport.date(2026, 11, 11, 15, 27))
        // everything else untouched
        XCTAssertEqual(times[.dhuhr], TestSupport.date(2026, 11, 11, 12, 0))
        XCTAssertEqual(times[.isha], TestSupport.date(2026, 11, 11, 19, 20))
    }

    func testAdjustedTimesDriveTheNextPrayer() throws {
        var settings = PrayerCalculationSettings.bangladeshDefault
        settings.adjustments.set(10, for: .dhuhr)   // Dhuhr now 12:10
        let service = PrayerScheduleService(calculator: calculator)
        let now = TestSupport.date(2026, 11, 11, 12, 5)
        let schedule = try service.schedule(for: now, location: TestSupport.dhakaLocation, settings: settings)
        XCTAssertEqual(schedule.next(after: now).prayer, .dhuhr)
        XCTAssertEqual(schedule.next(after: now).time, TestSupport.date(2026, 11, 11, 12, 10))
    }

    func testAdjustedTimesDriveTheReminders() {
        var settings = PrayerCalculationSettings.bangladeshDefault
        settings.adjustments.set(5, for: .maghrib)
        let planner = PrayerNotificationPlanner(calculator: calculator)
        let plan = planner.plan(now: day,
                                location: TestSupport.dhakaLocation,
                                settings: settings,
                                preferences: NotificationPreferences())
        let maghrib = plan.first { $0.identifier == "noortime.prayer.20261111.maghrib" }
        XCTAssertEqual(maghrib?.fireDate, TestSupport.date(2026, 11, 11, 18, 5))
    }

    func testRealCalculationRespectsAdjustments() throws {
        let real = AdjustedPrayerTimeCalculator.standard
        let plain = try real.entries(for: day, location: TestSupport.dhakaLocation, settings: .bangladeshDefault)
        var adjusted = PrayerCalculationSettings.bangladeshDefault
        adjusted.adjustments.set(-4, for: .fajr)
        let shifted = try real.entries(for: day, location: TestSupport.dhakaLocation, settings: adjusted)
        let before = plain.first { $0.prayer == .fajr }!.time
        let after = shifted.first { $0.prayer == .fajr }!.time
        XCTAssertEqual(before.timeIntervalSince(after), 240, accuracy: 0.001)
    }

    func testSwitchingAsrSchoolChangesAsrWithRealCalculation() throws {
        let real = AdjustedPrayerTimeCalculator.standard
        let hanafi = try real.entries(for: day, location: TestSupport.dhakaLocation, settings: .bangladeshDefault)
        var shafiSettings = PrayerCalculationSettings.bangladeshDefault
        shafiSettings.asrSchool = .shafi
        let shafi = try real.entries(for: day, location: TestSupport.dhakaLocation, settings: shafiSettings)
        let hanafiAsr = hanafi.first { $0.prayer == .asr }!.time
        let shafiAsr = shafi.first { $0.prayer == .asr }!.time
        XCTAssertGreaterThan(hanafiAsr, shafiAsr)
    }
}

// MARK: - Language override and the settings controller

@MainActor
final class AppSettingsControllerTests: XCTestCase {

    /// Runs `body` with a throw-away language store, then puts the real one back.
    private func isolated(_ body: () -> Void) {
        let saved = AppLanguage.defaults
        AppLanguage.defaults = makeDefaults()
        defer { AppLanguage.defaults = saved }
        body()
    }

    func testChoosingBengaliSwitchesTheAppLanguageAndIsRemembered() {
        isolated {
            let store = AppSettingsStore(defaults: makeDefaults())
            let controller = AppSettingsController(store: store)

            controller.settings.language = .bengali

            XCTAssertEqual(AppLanguage.code, "bn")
            XCTAssertEqual(controller.locale.identifier, "bn")
            XCTAssertEqual(store.load().language, .bengali)

            // Next launch: the choice is still applied.
            AppLanguage.setOverride(nil)
            _ = AppSettingsController(store: store)
            XCTAssertEqual(AppLanguage.code, "bn")
        }
    }

    func testChoosingEnglish() {
        isolated {
            let controller = AppSettingsController(store: AppSettingsStore(defaults: makeDefaults()))
            controller.settings.language = .english
            XCTAssertEqual(AppLanguage.code, "en")
            XCTAssertEqual(controller.locale.identifier, "en")
        }
    }

    func testFollowingTheIPhoneRemovesTheOverride() {
        isolated {
            let controller = AppSettingsController(store: AppSettingsStore(defaults: makeDefaults()))
            controller.settings.language = .bengali
            controller.settings.language = .system
            XCTAssertNil(AppLanguage.defaults.string(forKey: AppLanguage.storageKey))
            XCTAssertTrue(AppLanguage.supported.contains(AppLanguage.code))
        }
    }

    func testUnsupportedLanguageInStorageIsIgnored() {
        isolated {
            AppLanguage.defaults.set("fr", forKey: AppLanguage.storageKey)
            XCTAssertTrue(AppLanguage.supported.contains(AppLanguage.code))
            XCTAssertNotEqual(AppLanguage.code, "fr")
        }
    }

    func testThemeChoiceReachesTheColorScheme() {
        isolated {
            let controller = AppSettingsController(store: AppSettingsStore(defaults: makeDefaults()))
            XCTAssertNil(controller.colorScheme)
            controller.settings.theme = .dark
            XCTAssertEqual(controller.colorScheme, .dark)
            controller.settings.theme = .light
            XCTAssertEqual(controller.colorScheme, .light)
        }
    }

    func testCalculationChangesAreSaved() {
        isolated {
            let store = AppSettingsStore(defaults: makeDefaults())
            let controller = AppSettingsController(store: store)
            controller.settings.calculation.asrSchool = .shafi
            controller.settings.calculation.method = .egyptian
            let reloaded = AppSettingsController(store: store)
            XCTAssertEqual(reloaded.settings.calculation.asrSchool, .shafi)
            XCTAssertEqual(reloaded.settings.calculation.method, .egyptian)
        }
    }

    func testAdjustmentsAreClampedSavedAndResettable() {
        isolated {
            let store = AppSettingsStore(defaults: makeDefaults())
            let controller = AppSettingsController(store: store)

            controller.setAdjustment(99, for: .fajr)
            controller.setAdjustment(-4, for: .isha)
            XCTAssertEqual(controller.settings.calculation.adjustments.minutes(for: .fajr), 30)
            XCTAssertEqual(store.load().calculation.adjustments.minutes(for: .isha), -4)

            controller.resetAdjustments()
            XCTAssertTrue(controller.settings.calculation.adjustments.isZero)
            XCTAssertTrue(store.load().calculation.adjustments.isZero)
        }
    }

    func testFollowingTheIPhoneUsesTheAutoUpdatingLocale() {
        isolated {
            let controller = AppSettingsController(store: AppSettingsStore(defaults: makeDefaults()))
            XCTAssertEqual(controller.locale.identifier, Locale.autoupdatingCurrent.identifier)
        }
    }
}
