import CoreLocation

/// One-shot GPS using CoreLocation.
/// - Asks for "When In Use" permission only (never "Always").
/// - Uses `requestLocation()`: a single fix, then updates stop. No continuous tracking.
/// - Asks for kilometre accuracy, which is enough for prayer times.
@MainActor
final class CoreLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<GeoPoint, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var authTimeoutTask: Task<Void, Never>?

    private static let timeoutNanoseconds: UInt64 = 20_000_000_000        // 20 seconds for a fix
    private static let authTimeoutNanoseconds: UInt64 = 60_000_000_000    // 60 seconds for the permission pop-up

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var authorization: LocationAuthorization {
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        @unknown default: return .denied
        }
    }

    func currentLocation() async throws -> GeoPoint {
        // One request at a time.
        guard authContinuation == nil, locationContinuation == nil else {
            throw LocationError.unavailable
        }

        // 1. Permission (the iOS pop-up only appears the first time).
        if manager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                authContinuation = continuation
                // Safety net: never wait for the permission answer forever.
                authTimeoutTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: Self.authTimeoutNanoseconds)
                    guard !Task.isCancelled else { return }
                    self?.resumePermissionWaiter()
                }
                manager.requestWhenInUseAuthorization()
            }
        }
        switch authorization {
        case .authorized: break
        case .restricted: throw LocationError.permissionRestricted
        case .denied: throw LocationError.permissionDenied
        case .notDetermined: throw LocationError.unavailable   // no answer arrived in time
        }

        // 2. One position fix, with a time limit.
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GeoPoint, Error>) in
            locationContinuation = continuation
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: Self.timeoutNanoseconds)
                guard !Task.isCancelled else { return }
                self?.finish(.failure(LocationError.timeout))
            }
            manager.requestLocation()
        }
    }

    // MARK: - Finishing a request (always on the main actor, always only once)

    private func finish(_ result: Result<GeoPoint, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }

    private func authorizationDidChange() {
        guard manager.authorizationStatus != .notDetermined else { return }
        resumePermissionWaiter()
    }

    /// Wakes up the code waiting for the permission answer (answer arrived, or time ran out).
    private func resumePermissionWaiter() {
        authTimeoutTask?.cancel()
        authTimeoutTask = nil
        guard let continuation = authContinuation else { return }
        authContinuation = nil
        continuation.resume()
    }

    // MARK: - CLLocationManagerDelegate (called by iOS; hop back to the main actor)

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationDidChange()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let point = GeoPoint(latitude: last.coordinate.latitude, longitude: last.coordinate.longitude)
        Task { @MainActor in
            self.finish(.success(point))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        Task { @MainActor in
            self.finish(.failure(denied ? LocationError.permissionDenied : LocationError.unavailable))
        }
    }
}
