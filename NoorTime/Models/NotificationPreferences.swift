import Foundation

/// Which prayers send a reminder. Everything is ON by default.
/// (We store what is switched OFF, so a prayer added later also defaults to ON.)
struct NotificationPreferences: Codable, Equatable {
    private(set) var disabled: Set<String> = []

    /// Sunrise is not a prayer, so it never gets a reminder.
    func isEnabled(_ prayer: Prayer) -> Bool {
        prayer.isPrayer && !disabled.contains(prayer.rawValue)
    }

    mutating func set(_ prayer: Prayer, enabled: Bool) {
        if enabled {
            disabled.remove(prayer.rawValue)
        } else {
            disabled.insert(prayer.rawValue)
        }
    }
}

/// Saves `NotificationPreferences` in UserDefaults (on this iPhone only).
struct NotificationPreferencesStore {
    static let key = "noortime.notificationPreferences.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> NotificationPreferences {
        guard let data = defaults.data(forKey: Self.key),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return NotificationPreferences()
        }
        return preferences
    }

    func save(_ preferences: NotificationPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
