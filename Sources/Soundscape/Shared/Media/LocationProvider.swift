import CoreLocation
import Foundation

struct Place: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let name: String
}

protocol LocationProviding: Sendable {
    func currentPlace() async throws -> Place
}

final class OneShotLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private let lock = NSLock()
    private var continuations: [CheckedContinuation<Place, Error>] = []
    private var isRequesting = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentPlace() async throws -> Place {
        try await withCheckedThrowingContinuation { continuation in
            let shouldStart = lock.withLock {
                continuations.append(continuation)
                guard !isRequesting else { return false }
                isRequesting = true
                return true
            }
            guard shouldStart else { return }
            DispatchQueue.main.async { self.startRequestIfAuthorized() }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startRequestIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let placemark = placemarks?.first
            let name = [placemark?.locality, placemark?.subLocality, placemark?.name]
                .compactMap { $0 }
                .uniqued()
                .joined(separator: " · ")
            self?.resume(.success(Place(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: name
            )))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(.failure(AppError.locationUnavailable))
    }

    private func resume(_ result: Result<Place, Error>) {
        let waiting = lock.withLock {
            defer {
                continuations = []
                isRequesting = false
            }
            return continuations
        }
        waiting.forEach { $0.resume(with: result) }
    }

    private func startRequestIfAuthorized() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resume(.failure(AppError.locationUnavailable))
        @unknown default:
            resume(.failure(AppError.locationUnavailable))
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
