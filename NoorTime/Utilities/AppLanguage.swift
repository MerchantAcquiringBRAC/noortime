import Foundation

/// The language the app is shown in: "en" or "bn".
/// The user can choose it in Settings; "follow the iPhone" is the default.
enum AppLanguage {
    static let supported = ["en", "bn"]
    static let storageKey = "noortime.languageOverride"

    /// Where the choice is kept. Tests replace this with a throw-away store.
    static var defaults: UserDefaults = .standard

    static var code: String {
        if let chosen = defaults.string(forKey: storageKey), supported.contains(chosen) {
            return chosen
        }
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        return supported.contains(preferred) ? preferred : "en"
    }

    /// Pass nil to follow the iPhone's language again.
    static func setOverride(_ code: String?) {
        if let code, supported.contains(code) {
            defaults.set(code, forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
        }
    }
}
