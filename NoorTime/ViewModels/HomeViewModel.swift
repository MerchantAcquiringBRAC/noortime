import Foundation

/// Drives the home screen. All prayer times come from `PrayerScheduleService` (Adhan Swift).
@MainActor
final class HomeViewModel: ObservableObject {
    /// nil means the calculation failed; the screen then shows an error card with a retry button.
    @Published private(set) var schedule: DailyPrayerSchedule?
    @Published private(set) var place: Place
    @Published private(set) var settings: PrayerCalculationSettings
    @Published var notificationStatus: NotificationStatus = .notSetUp

    private let service: PrayerScheduleService

    init(place: Place? = nil,
         settings: PrayerCalculationSettings = .bangladeshDefault,
         service: PrayerScheduleService = PrayerScheduleService(),
         now: Date = Date()) {
        self.place = place ?? PlaceStore().loadOrDefault()
        self.settings = settings
        self.service = service
        reload(now: now)
    }

    var timeZone: TimeZone { place.timeZone }

    /// "Dhaka, Bangladesh" in the app language, or nil when the place has no name yet
    /// (the screen then shows the localized "Current location").
    var locationTitle: String? {
        let language = AppLanguage.code
        guard let name = place.displayName(languageCode: language) else { return nil }
        if let country = place.countryName(languageCode: language) {
            return "\(name), \(country)"
        }
        return name
    }

    /// Switches to another place and recalculates.
    func setPlace(_ newPlace: Place, now: Date = Date()) {
        guard newPlace != place else { return }
        place = newPlace
        reload(now: now)
    }

    /// Recalculates today's schedule from scratch.
    func reload(now: Date = Date()) {
        schedule = try? service.schedule(for: now, location: place.location, settings: settings)
    }

    /// Cheap check, safe to call often: recalculates only after midnight
    /// (in the place's time zone) or when the last calculation failed.
    func refreshIfNeeded(now: Date) {
        guard let current = schedule else {
            reload(now: now)
            return
        }
        if !current.isCurrent(at: now, timeZone: timeZone) {
            reload(now: now)
        }
    }
}
