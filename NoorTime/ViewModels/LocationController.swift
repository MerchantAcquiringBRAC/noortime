import Foundation

/// Owns "which place are prayer times for?": GPS, a manually chosen city, or the default.
@MainActor
final class LocationController: ObservableObject {
    enum RequestState: Equatable {
        case idle
        case locating
        case failed(LocationError)
    }

    @Published private(set) var place: Place
    @Published private(set) var requestState: RequestState = .idle
    @Published private(set) var authorization: LocationAuthorization

    let cities: [City]

    /// After a GPS place is set, it is re-checked in the background at most this often.
    static let automaticRefreshInterval: TimeInterval = 30 * 60

    private let provider: LocationProviding
    private let resolver: PlaceResolving
    private let store: PlaceStore
    private var lastSuccessfulFix: Date?
    private var lastSilentAttempt: Date?
    /// Goes up every time the user picks a city, so a GPS answer that arrives
    /// late can tell that the user has already decided something else.
    private var requestGeneration = 0

    init(provider: LocationProviding? = nil,
         resolver: PlaceResolving = CLGeocoderPlaceResolver(),
         store: PlaceStore = PlaceStore(),
         cities: [City]? = nil) {
        let actualProvider = provider ?? CoreLocationProvider()
        self.provider = actualProvider
        self.resolver = resolver
        self.store = store
        self.place = store.loadOrDefault()
        self.authorization = actualProvider.authorization
        self.cities = cities ?? ((try? CityRepository.loadCities()) ?? [City.dhakaFallback])
    }

    func refreshAuthorization() {
        authorization = provider.authorization
    }

    /// The user tapped "Use my current location". May show the iOS permission pop-up.
    func useCurrentLocation(now: Date = Date()) async {
        await performGPSRequest(silent: false, now: now)
    }

    /// Quietly updates a GPS place (for example after travelling).
    /// Never shows the permission pop-up, never shows errors, and tries at most every 30 minutes
    /// (whether or not the last try worked).
    func refreshGPSIfNeeded(now: Date = Date()) async {
        guard place.source == .gps, provider.authorization == .authorized else { return }
        let lastTry = [lastSuccessfulFix, lastSilentAttempt].compactMap { $0 }.max()
        if let lastTry, now.timeIntervalSince(lastTry) < Self.automaticRefreshInterval {
            return
        }
        await performGPSRequest(silent: true, now: now)
    }

    /// The user picked a city from the list. This always wins over a GPS request still in progress.
    func select(city: City) {
        requestGeneration += 1
        apply(Place.city(city, source: .manual))
        if requestState != .locating {
            requestState = .idle
        }
    }

    // MARK: - Private

    private func performGPSRequest(silent: Bool, now: Date) async {
        guard requestState != .locating else { return }
        requestState = .locating
        if silent { lastSilentAttempt = now }
        let generation = requestGeneration

        let outcome: Result<Place, LocationError>
        do {
            let point = try await provider.currentLocation().rounded
            let info = await resolver.resolve(latitude: point.latitude, longitude: point.longitude)
            outcome = .success(Place.gps(point: point, info: info))
        } catch let error as LocationError {
            outcome = .failure(error)
        } catch {
            outcome = .failure(.unavailable)
        }

        refreshAuthorization()

        // The user chose a city while we were waiting for GPS: their choice stays.
        guard generation == requestGeneration else {
            requestState = .idle
            return
        }

        switch outcome {
        case .success(let newPlace):
            apply(newPlace)
            lastSuccessfulFix = now
            requestState = .idle
        case .failure(let error):
            requestState = silent ? .idle : .failed(error)
        }
    }

    private func apply(_ newPlace: Place) {
        guard newPlace != place else { return }
        place = newPlace
        store.save(newPlace)
    }
}
