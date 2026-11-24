import Foundation

/// Looks up a translated string for a specific language ("en" or "bn"),
/// independent of the phone's language. Used for notification text, which is
/// written when the reminder is scheduled.
enum Localizer {
    static func string(_ key: String, language: String, bundle: Bundle = AppBundle.main) -> String {
        if let path = bundle.path(forResource: language, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            return languageBundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
