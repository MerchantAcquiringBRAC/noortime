import Foundation

/// A point on Earth.
struct GeoPoint: Equatable, Codable {
    let latitude: Double
    let longitude: Double

    /// Rounded to 2 decimals (about 1 km). That is plenty for prayer times
    /// (a few seconds of difference) and kinder to the user's privacy.
    var rounded: GeoPoint {
        GeoPoint(latitude: (latitude * 100).rounded() / 100,
                 longitude: (longitude * 100).rounded() / 100)
    }
}

/// What the app knows about the iOS location permission.
enum LocationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Why getting the current location failed.
enum LocationError: Error, Equatable {
    case permissionDenied
    case permissionRestricted
    case unavailable
    case timeout
}

/// City name, country and time zone found by reverse geocoding. Any part may be missing.
struct PlaceInfo: Equatable {
    var nameEn: String?
    var nameBn: String?
    var countryCode: String?
    var timeZone: TimeZone?

    static let empty = PlaceInfo(nameEn: nil, nameBn: nil, countryCode: nil, timeZone: nil)
}
