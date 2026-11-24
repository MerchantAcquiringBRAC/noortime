import Foundation

/// Gets the phone's current position once. The real version uses CoreLocation;
/// tests use a stand-in.
@MainActor
protocol LocationProviding {
    var authorization: LocationAuthorization { get }

    /// Asks for permission if it has not been asked yet, then returns ONE position fix.
    /// It never keeps tracking in the background.
    func currentLocation() async throws -> GeoPoint
}

/// Turns coordinates into a city name, country and time zone (reverse geocoding).
protocol PlaceResolving {
    /// Never throws: if the lookup fails the result simply has missing parts.
    func resolve(latitude: Double, longitude: Double) async -> PlaceInfo
}
