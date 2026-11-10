import Foundation

/// Where prayer times are calculated: a point on Earth plus that place's own time zone.
/// (Phase 3 will create this from GPS or from a manually chosen city.)
struct PrayerLocation: Equatable {
    let latitude: Double
    let longitude: Double
    let timeZone: TimeZone
}
