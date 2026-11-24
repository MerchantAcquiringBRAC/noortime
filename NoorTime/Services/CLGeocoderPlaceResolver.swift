import CoreLocation

/// Reverse geocoding with Apple's CLGeocoder.
/// PRIVACY NOTE: iOS sends the (rounded) coordinate to Apple's map service to get the city name.
/// NoorTime itself has no server and sends nothing anywhere. The privacy text says this.
struct CLGeocoderPlaceResolver: PlaceResolving {

    func resolve(latitude: Double, longitude: Double) async -> PlaceInfo {
        let location = CLLocation(latitude: latitude, longitude: longitude)

        // Ask for English and Bengali names at the same time (two separate geocoders).
        async let english = Self.lookup(location, languageCode: "en")
        async let bengali = Self.lookup(location, languageCode: "bn")
        let (en, bn) = await (english, bengali)

        let primary = en ?? bn
        return PlaceInfo(nameEn: en?.name ?? bn?.name,
                         nameBn: bn?.name ?? en?.name,
                         countryCode: primary?.countryCode,
                         timeZone: primary?.timeZone)
    }

    private struct Lookup {
        let name: String?
        let countryCode: String?
        let timeZone: TimeZone?
    }

    private static func lookup(_ location: CLLocation, languageCode: String) async -> Lookup? {
        do {
            let marks = try await CLGeocoder().reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: languageCode)
            )
            guard let mark = marks.first else { return nil }
            let name = mark.locality ?? mark.subAdministrativeArea ?? mark.administrativeArea ?? mark.name
            return Lookup(name: name, countryCode: mark.isoCountryCode, timeZone: mark.timeZone)
        } catch {
            return nil
        }
    }
}
