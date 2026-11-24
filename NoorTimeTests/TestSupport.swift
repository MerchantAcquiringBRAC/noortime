import Foundation
@testable import NoorTime

/// Shared helpers for the unit tests.
enum TestSupport {
    static let dhaka = TimeZone(identifier: "Asia/Dhaka")!

    static let dhakaLocation = PrayerLocation(latitude: 23.8103, longitude: 90.4125, timeZone: dhaka)

    static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// A moment in time, written as local clock time in `timeZone` (Dhaka by default).
    static func date(_ year: Int, _ month: Int, _ day: Int,
                     _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0,
                     in timeZone: TimeZone = dhaka) -> Date {
        let parts = DateComponents(year: year, month: month, day: day,
                                   hour: hour, minute: minute, second: second)
        return calendar(timeZone).date(from: parts)!
    }

    /// Minutes since local midnight, e.g. 04:55 -> 295.
    static func minutesOfDay(_ date: Date, in timeZone: TimeZone = dhaka) -> Int {
        let parts = calendar(timeZone).dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    static func localDay(_ date: Date, in timeZone: TimeZone = dhaka) -> DateComponents {
        calendar(timeZone).dateComponents([.year, .month, .day], from: date)
    }
}

/// Fixed, predictable prayer times so next-prayer logic can be tested exactly.
/// Fajr 05:00, Sunrise 06:15, Dhuhr 12:00, Asr 15:30, Maghrib 18:00, Isha 19:20 (local).
struct StubCalculator: PrayerTimeCalculating {
    func entries(for date: Date,
                 location: PrayerLocation,
                 settings: PrayerCalculationSettings) throws -> [PrayerEntry] {
        let start = TestSupport.calendar(location.timeZone).startOfDay(for: date)
        let table: [(Prayer, Int)] = [
            (.fajr, 5 * 60),
            (.sunrise, 6 * 60 + 15),
            (.dhuhr, 12 * 60),
            (.asr, 15 * 60 + 30),
            (.maghrib, 18 * 60),
            (.isha, 19 * 60 + 20)
        ]
        return table.map { PrayerEntry(prayer: $0.0, time: start.addingTimeInterval(TimeInterval($0.1 * 60))) }
    }
}

struct FailingCalculator: PrayerTimeCalculating {
    func entries(for date: Date,
                 location: PrayerLocation,
                 settings: PrayerCalculationSettings) throws -> [PrayerEntry] {
        throw PrayerTimeError.calculationFailed
    }
}

// MARK: - Phase 3 stand-ins

/// Pretends to be the phone's GPS. No real location is ever used in tests.
@MainActor
final class FakeLocationProvider: LocationProviding {
    var authorization: LocationAuthorization = .authorized
    var result: Result<GeoPoint, LocationError> = .success(GeoPoint(latitude: 23.81034, longitude: 90.41256))
    private(set) var callCount = 0
    /// Runs in the middle of a request, to simulate something happening while GPS is busy.
    var onCall: (@MainActor () -> Void)?

    func currentLocation() async throws -> GeoPoint {
        callCount += 1
        onCall?()
        return try result.get()
    }
}

/// Pretends to be reverse geocoding.
struct FakeResolver: PlaceResolving {
    var info: PlaceInfo

    func resolve(latitude: Double, longitude: Double) async -> PlaceInfo {
        info
    }
}

extension PlaceInfo {
    static let dhaka = PlaceInfo(nameEn: "Dhaka",
                                 nameBn: "ঢাকা",
                                 countryCode: "BD",
                                 timeZone: TestSupport.dhaka)
}
