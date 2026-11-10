import Foundation

enum PrayerTimeError: Error {
    /// The calculation library could not produce times (for example, extreme polar latitudes).
    case calculationFailed
}

/// Anything that can calculate one day of prayer times.
/// The real app uses Adhan Swift; the tests use a simple stand-in.
protocol PrayerTimeCalculating {
    /// Returns Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha (in that order) for the
    /// calendar day that `date` falls on **in the location's own time zone**.
    func entries(for date: Date,
                 location: PrayerLocation,
                 settings: PrayerCalculationSettings) throws -> [PrayerEntry]
}
