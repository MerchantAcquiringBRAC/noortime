import Foundation

/// Saves the selected place in UserDefaults (on this iPhone only).
struct PlaceStore {
    static let key = "noortime.selectedPlace.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// nil if nothing was saved yet, or the saved data cannot be read.
    func load() -> Place? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(Place.self, from: data)
    }

    func save(_ place: Place) {
        guard let data = try? JSONEncoder().encode(place) else { return }
        defaults.set(data, forKey: Self.key)
    }

    /// The saved place, or Dhaka (marked as the default city) on first launch.
    func loadOrDefault() -> Place {
        load() ?? Place.city(CityRepository.defaultCity, source: .defaultCity)
    }
}
