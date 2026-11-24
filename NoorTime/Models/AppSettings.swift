import SwiftUI

/// App language choice. "system" follows the iPhone's language.
enum LanguageChoice: String, Codable, CaseIterable, Identifiable {
    case system
    case english
    case bengali

    var id: String { rawValue }

    /// "en" / "bn", or nil for "follow the iPhone".
    var code: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .bengali: return "bn"
        }
    }
}

/// Light / dark theme choice. "system" follows the iPhone.
enum ThemeChoice: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "settings.theme.system"
        case .light: return "settings.theme.light"
        case .dark: return "settings.theme.dark"
        }
    }
}

/// All user settings that are not about notifications or the chosen place.
struct AppSettings: Codable, Equatable {
    var language: LanguageChoice = .system
    var theme: ThemeChoice = .system
    var calculation: PrayerCalculationSettings = .bangladeshDefault
}
