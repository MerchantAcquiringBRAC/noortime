import Foundation

/// One day of prayer times, plus tomorrow's Fajr (needed after Isha).
struct DailyPrayerSchedule: Equatable {
    /// The moment this schedule was calculated for (used to know which day it covers).
    let date: Date
    let entries: [PrayerEntry]
    let tomorrowFajr: PrayerEntry

    /// The next real prayer after `now`. Sunrise is never "next prayer".
    /// After Isha this is tomorrow's Fajr.
    func next(after now: Date) -> PrayerEntry {
        entries.first { $0.prayer.isPrayer && $0.time > now } ?? tomorrowFajr
    }

    /// True while `now` is still on the same calendar day (in `timeZone`) as this schedule.
    func isCurrent(at now: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(date, inSameDayAs: now)
    }
}

/// Builds a `DailyPrayerSchedule` using any `PrayerTimeCalculating` implementation.
struct PrayerScheduleService {
    private let calculator: PrayerTimeCalculating

    init(calculator: PrayerTimeCalculating = AdhanPrayerTimeService()) {
        self.calculator = calculator
    }

    func schedule(for date: Date,
                  location: PrayerLocation,
                  settings: PrayerCalculationSettings) throws -> DailyPrayerSchedule {
        let today = try calculator.entries(for: date, location: location, settings: settings)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone
        guard let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) else {
            throw PrayerTimeError.calculationFailed
        }
        let tomorrow = try calculator.entries(for: tomorrowDate, location: location, settings: settings)

        guard let tomorrowFajr = tomorrow.first(where: { $0.prayer == .fajr }) else {
            throw PrayerTimeError.calculationFailed
        }
        return DailyPrayerSchedule(date: date, entries: today, tomorrowFajr: tomorrowFajr)
    }
}
