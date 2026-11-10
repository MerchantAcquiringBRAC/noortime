import Foundation

/// Drives the home screen. All prayer times come from `PrayerScheduleService`
/// (Adhan Swift); there is no sample data any more.
@MainActor
final class HomeViewModel: ObservableObject {
    /// nil means the calculation failed; the screen then shows an error card with a retry button.
    @Published private(set) var schedule: DailyPrayerSchedule?
    @Published private(set) var city: City
    @Published private(set) var settings: PrayerCalculationSettings
    @Published var notificationStatus: NotificationStatus = .notSetUp

    private let service: PrayerScheduleService

    init(city: City = CityRepository.defaultCity,
         settings: PrayerCalculationSettings = .bangladeshDefault,
         service: PrayerScheduleService = PrayerScheduleService(),
         now: Date = Date()) {
        self.city = city
        self.settings = settings
        self.service = service
        reload(now: now)
    }

    var timeZone: TimeZone { city.timeZone }

    /// "Dhaka, Bangladesh" in the phone's language (English or Bengali).
    var locationTitle: String {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let country = Locale(identifier: language).localizedString(forRegionCode: city.countryCode)
            ?? city.countryCode
        return "\(city.displayName(languageCode: language)), \(country)"
    }

    /// Recalculates today's schedule from scratch.
    func reload(now: Date = Date()) {
        schedule = try? service.schedule(for: now, location: city.location, settings: settings)
    }

    /// Cheap check, safe to call often: recalculates only after midnight
    /// (in the city's time zone) or when the last calculation failed.
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
