import Foundation

/// A city from `Cities.json`. Works for any country, so more countries can be added later
/// by only editing the JSON file.
struct City: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let nameEn: String
    let nameBn: String
    /// Two-letter country code, e.g. "BD".
    let countryCode: String
    let latitude: Double
    let longitude: Double
    /// IANA time zone name, e.g. "Asia/Dhaka".
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var location: PrayerLocation {
        PrayerLocation(latitude: latitude, longitude: longitude, timeZone: timeZone)
    }

    func displayName(languageCode: String) -> String {
        languageCode == "bn" ? nameBn : nameEn
    }
}

extension City {
    /// Built-in copy of Dhaka. It is the real city, used only if `Cities.json` cannot be read,
    /// so the app never opens to an empty screen.
    static let dhakaFallback = City(
        id: "dhaka",
        nameEn: "Dhaka",
        nameBn: "ঢাকা",
        countryCode: "BD",
        latitude: 23.8103,
        longitude: 90.4125,
        timeZoneIdentifier: "Asia/Dhaka"
    )
}
