import SwiftUI

/// Holds the user's settings, saves every change, and tells the rest of the app
/// which language, locale and theme to use.
@MainActor
final class AppSettingsController: ObservableObject {
    @Published var settings: AppSettings {
        didSet { persistIfChanged(from: oldValue) }
    }

    private let store: AppSettingsStore

    init(store: AppSettingsStore = AppSettingsStore()) {
        self.store = store
        let loaded = store.load()
        self.settings = loaded
        AppLanguage.setOverride(loaded.language.code)
    }

    /// Locale for the whole UI (text lookup, date and number formats).
    /// "Follow the iPhone" keeps the phone's own regional formats.
    var locale: Locale {
        if let code = settings.language.code {
            return Locale(identifier: code)
        }
        return .autoupdatingCurrent
    }

    var colorScheme: ColorScheme? {
        settings.theme.colorScheme
    }

    func setAdjustment(_ minutes: Int, for prayer: Prayer) {
        settings.calculation.adjustments.set(minutes, for: prayer)
    }

    func resetAdjustments() {
        settings.calculation.adjustments.reset()
    }

    private func persistIfChanged(from old: AppSettings) {
        guard settings != old else { return }
        store.save(settings)
        AppLanguage.setOverride(settings.language.code)
    }
}
