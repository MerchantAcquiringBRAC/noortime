import Foundation

/// The language the app is currently shown in: "en" or "bn".
/// (Phase 5 adds an in-app language switch; it will plug in here.)
enum AppLanguage {
    static var code: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
}
