import Adhan
import Foundation

/// Calculates prayer times with the Adhan Swift library.
/// This is the only file in the app that imports Adhan.
struct AdhanPrayerTimeService: PrayerTimeCalculating {

    func entries(for date: Date,
                 location: PrayerLocation,
                 settings: PrayerCalculationSettings) throws -> [PrayerEntry] {

        // Find the calendar day in the LOCATION's time zone (not the phone's).
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let day = DateComponents(year: parts.year, month: parts.month, day: parts.day)

        var parameters = settings.method.adhanMethod.params
        parameters.madhab = settings.asrSchool.adhanMadhab

        let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)

        guard let times = PrayerTimes(coordinates: coordinates,
                                      date: day,
                                      calculationParameters: parameters) else {
            throw PrayerTimeError.calculationFailed
        }

        return [
            PrayerEntry(prayer: .fajr, time: times.fajr),
            PrayerEntry(prayer: .sunrise, time: times.sunrise),
            PrayerEntry(prayer: .dhuhr, time: times.dhuhr),
            PrayerEntry(prayer: .asr, time: times.asr),
            PrayerEntry(prayer: .maghrib, time: times.maghrib),
            PrayerEntry(prayer: .isha, time: times.isha)
        ]
    }
}

// MARK: - Mapping NoorTime settings to Adhan settings

private extension CalculationMethodOption {
    var adhanMethod: CalculationMethod {
        switch self {
        case .karachi: return .karachi
        case .muslimWorldLeague: return .muslimWorldLeague
        case .egyptian: return .egyptian
        case .ummAlQura: return .ummAlQura
        case .northAmerica: return .northAmerica
        case .moonsightingCommittee: return .moonsightingCommittee
        }
    }
}

private extension AsrSchool {
    var adhanMadhab: Madhab {
        switch self {
        case .hanafi: return .hanafi
        case .shafi: return .shafi
        }
    }
}
