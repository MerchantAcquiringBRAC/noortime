import SwiftUI

enum PlaceSource: String, Codable {
    /// Found with GPS.
    case gps
    /// Chosen by the user from the city list.
    case manual
    /// The built-in starting city (Dhaka) before the user chooses anything.
    case defaultCity

    var labelKey: LocalizedStringKey {
        switch self {
        case .gps: return "location.source.gps"
        case .manual: return "location.source.manual"
        case .defaultCity: return "location.source.default"
        }
    }
}

/// The place prayer times are calculated for. Saved on the phone so the app
/// still works offline after a restart.
struct Place: Codable, Equatable {
    let source: PlaceSource
    /// Set for cities from Cities.json, nil for GPS places.
    let cityID: String?
    /// nil when no name could be found (the screen then shows "Current location").
    let nameEn: String?
    let nameBn: String?
    let countryCode: String?
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var location: PrayerLocation {
        PrayerLocation(latitude: latitude, longitude: longitude, timeZone: timeZone)
    }

    func displayName(languageCode: String) -> String? {
        let preferred = languageCode == "bn" ? nameBn : nameEn
        return preferred ?? nameEn ?? nameBn
    }

    func countryName(languageCode: String) -> String? {
        guard let countryCode else { return nil }
        return Locale(identifier: languageCode).localizedString(forRegionCode: countryCode)
    }

    static func city(_ city: City, source: PlaceSource) -> Place {
        Place(source: source,
              cityID: city.id,
              nameEn: city.nameEn,
              nameBn: city.nameBn,
              countryCode: city.countryCode,
              latitude: city.latitude,
              longitude: city.longitude,
              timeZoneIdentifier: city.timeZoneIdentifier)
    }

    /// A GPS place. The coordinates are rounded (see `GeoPoint.rounded`).
    /// If geocoding gave no time zone, `TimeZoneFallback` picks one.
    static func gps(point: GeoPoint, info: PlaceInfo) -> Place {
        let rounded = point.rounded
        let zone = info.timeZone ?? TimeZoneFallback.zone(for: rounded)
        return Place(source: .gps,
                     cityID: nil,
                     nameEn: info.nameEn,
                     nameBn: info.nameBn,
                     countryCode: info.countryCode,
                     latitude: rounded.latitude,
                     longitude: rounded.longitude,
                     timeZoneIdentifier: zone.identifier)
    }
}

/// Used only when reverse geocoding (an internet lookup) gave no time zone.
/// GPS means the phone is at this spot, so the phone's own time zone is the best answer.
/// (A rectangle around Bangladesh would be wrong: it also contains Kolkata and Assam, which are
/// 30 minutes behind.)
enum TimeZoneFallback {
    static func zone(for point: GeoPoint) -> TimeZone {
        .current
    }
}
