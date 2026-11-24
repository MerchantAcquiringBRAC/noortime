import SwiftUI

/// Which published calculation method to use.
/// New methods can be added here later without touching the screens.
enum CalculationMethodOption: String, Codable, CaseIterable, Identifiable {
    case karachi
    case muslimWorldLeague
    case egyptian
    case ummAlQura
    case northAmerica
    case moonsightingCommittee

    var id: String { rawValue }

    /// Key in Localizable.strings, e.g. "method.karachi".
    var localizationKey: String { "method.\(rawValue)" }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(localizationKey)
    }
}

/// Asr prayer calculation school.
enum AsrSchool: String, Codable, CaseIterable, Identifiable {
    /// Hanafi: Asr starts later (shadow = 2x object length).
    case hanafi
    /// Shafi'i / standard: Asr starts earlier (shadow = 1x object length).
    case shafi

    var id: String { rawValue }

    /// Key in Localizable.strings, e.g. "asr.hanafi".
    var localizationKey: String { "asr.\(rawValue)" }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(localizationKey)
    }
}

/// Everything the calculation needs besides the location.
struct PrayerCalculationSettings: Codable, Equatable {
    var method: CalculationMethodOption
    var asrSchool: AsrSchool

    /// Bangladesh-first defaults: Karachi method, Hanafi Asr.
    /// These are calculation settings, not a verified local authority timetable.
    static let bangladeshDefault = PrayerCalculationSettings(method: .karachi, asrSchool: .hanafi)
}
