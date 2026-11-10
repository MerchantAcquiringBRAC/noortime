import Foundation

enum CityRepositoryError: Error {
    case fileMissing
}

/// Loads the list of cities from `Cities.json`.
enum CityRepository {
    static func loadCities(bundle: Bundle = AppBundle.main) throws -> [City] {
        guard let url = bundle.url(forResource: "Cities", withExtension: "json") else {
            throw CityRepositoryError.fileMissing
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([City].self, from: data)
    }

    /// Dhaka is the default city until the user picks GPS or another city (Phase 3).
    static var defaultCity: City {
        let cities = (try? loadCities()) ?? []
        return cities.first { $0.id == City.dhakaFallback.id } ?? City.dhakaFallback
    }
}
