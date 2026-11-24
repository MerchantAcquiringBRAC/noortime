import Foundation

/// Owns notification permission, the per-prayer switches, and keeps iOS's scheduled
/// reminders in step with the current place and calculation settings.
@MainActor
final class NotificationController: ObservableObject {
    @Published private(set) var status: NotificationStatus = .notSetUp
    @Published private(set) var preferences: NotificationPreferences

    private struct Context {
        let location: PrayerLocation
        let settings: PrayerCalculationSettings
    }

    private let center: NotificationCenterProviding
    private let scheduler: PrayerNotificationScheduler
    private let store: NotificationPreferencesStore
    private let language: () -> String
    private var context: Context?
    /// Syncs run one after another, never at the same time.
    private var lastSync: Task<Void, Never>?

    init(center: NotificationCenterProviding? = nil,
         planner: PrayerNotificationPlanner = PrayerNotificationPlanner(),
         store: NotificationPreferencesStore = NotificationPreferencesStore(),
         language: @escaping () -> String = { AppLanguage.code }) {
        let actualCenter = center ?? SystemNotificationCenter()
        self.center = actualCenter
        self.scheduler = PrayerNotificationScheduler(center: actualCenter, planner: planner)
        self.store = store
        self.language = language
        self.preferences = store.load()
    }

    /// Asks iOS for permission. Call this ONLY from a button the user tapped.
    /// If the user allows, reminders are scheduled straight away.
    func requestPermission(now: Date = Date()) async {
        if await center.authorization() == .notDetermined {
            _ = try? await center.requestAuthorization()
        }
        await runSync(now: now)
    }

    /// Brings iOS in step with the current place and settings.
    /// Call on app start, when the app returns to the foreground, and when the place,
    /// calculation method or Asr school changes.
    func sync(location: PrayerLocation,
              settings: PrayerCalculationSettings,
              now: Date = Date()) async {
        context = Context(location: location, settings: settings)
        await runSync(now: now)
    }

    /// Switch one prayer's reminder on or off.
    func setEnabled(_ prayer: Prayer, _ enabled: Bool, now: Date = Date()) async {
        var updated = preferences
        updated.set(prayer, enabled: enabled)
        guard updated != preferences else { return }
        preferences = updated
        store.save(updated)
        await runSync(now: now)
    }

    // MARK: - Private

    private func runSync(now: Date) async {
        let previous = lastSync
        let task = Task { @MainActor in
            await previous?.value
            await self.performSync(now: now)
        }
        lastSync = task
        await task.value
    }

    private func performSync(now: Date) async {
        status = NotificationStatus(await center.authorization())
        guard let context else { return }

        if status == .enabled {
            _ = await scheduler.reconcile(now: now,
                                          location: context.location,
                                          settings: context.settings,
                                          preferences: preferences,
                                          language: language())
        } else {
            // No permission: make sure nothing stale is left waiting in iOS.
            await scheduler.cancelAll()
        }
    }
}
