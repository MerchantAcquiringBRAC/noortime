import SwiftUI

/// The five daily prayers plus sunrise (sunrise is shown but is not a prayer).
enum Prayer: String, CaseIterable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    /// Sunrise is displayed in the list, but never counted as "next prayer".
    var isPrayer: Bool { self != .sunrise }

    /// Key in Localizable.strings, e.g. "prayer.fajr".
    var localizationKey: String { "prayer.\(rawValue)" }

    var titleKey: LocalizedStringKey {
        // Build the key as a plain String first. Writing an interpolation directly inside
        // LocalizedStringKey("...\(x)") would look up "prayer.%@" and fail.
        LocalizedStringKey(localizationKey)
    }

    var symbolName: String {
        switch self {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }
}

/// One line in the daily list: which prayer, and at what moment.
struct PrayerEntry: Identifiable, Equatable {
    let prayer: Prayer
    let time: Date

    var id: String { prayer.rawValue }
}
