import Foundation

/// Wraps another calculator and adds the user's manual minute corrections to its results.
/// Used for the real app (around Adhan) so the home screen AND the reminders agree.
struct AdjustedPrayerTimeCalculator: PrayerTimeCalculating {
    let base: PrayerTimeCalculating

    func entries(for date: Date,
                 location: PrayerLocation,
                 settings: PrayerCalculationSettings) throws -> [PrayerEntry] {
        let list = try base.entries(for: date, location: location, settings: settings)
        guard !settings.adjustments.isZero else { return list }

        return list.map { entry in
            let minutes = settings.adjustments.minutes(for: entry.prayer)
            return PrayerEntry(prayer: entry.prayer,
                               time: entry.time.addingTimeInterval(TimeInterval(minutes) * 60))
        }
    }
}

extension AdjustedPrayerTimeCalculator {
    /// The calculator the real app uses: Adhan Swift plus manual adjustments.
    static var standard: AdjustedPrayerTimeCalculator {
        AdjustedPrayerTimeCalculator(base: AdhanPrayerTimeService())
    }
}
