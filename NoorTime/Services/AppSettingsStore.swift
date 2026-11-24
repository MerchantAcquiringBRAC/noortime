import Foundation

/// Saves `AppSettings` in UserDefaults (on this iPhone only).
struct AppSettingsStore {
    static let key = "noortime.appSettings.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Saved settings, or the defaults (Karachi, Hanafi, system language and theme)
    /// when nothing was saved or the saved data cannot be read.
    func load() -> AppSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
