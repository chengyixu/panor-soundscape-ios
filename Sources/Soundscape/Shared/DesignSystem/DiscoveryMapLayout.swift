import CoreGraphics
import MapKit

enum DiscoveryMapLayout {
    static let minimumMapHeight: CGFloat = 360
    static let maximumMapHeight: CGFloat = 560

    static func mapHeight(availableHeight: CGFloat) -> CGFloat {
        min(maximumMapHeight, max(minimumMapHeight, availableHeight - 120))
    }
}

enum DiscoveryMapViewport {
    private static let minimumSpan = 0.24
    private static let paddingFactor = 1.35

    static func overviewRegion(for items: [Soundscape]) -> MKCoordinateRegion? {
        let coordinates = items.compactMap { item -> CLLocationCoordinate2D? in
            guard let latitude = item.latitude, let longitude = item.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        guard let first = coordinates.first else { return nil }

        let bounds = coordinates.dropFirst().reduce(
            (minLatitude: first.latitude, maxLatitude: first.latitude,
             minLongitude: first.longitude, maxLongitude: first.longitude)
        ) { bounds, coordinate in
            (
                min(bounds.minLatitude, coordinate.latitude),
                max(bounds.maxLatitude, coordinate.latitude),
                min(bounds.minLongitude, coordinate.longitude),
                max(bounds.maxLongitude, coordinate.longitude)
            )
        }
        let latitudeDelta = max(minimumSpan, (bounds.maxLatitude - bounds.minLatitude) * paddingFactor)
        let longitudeDelta = max(minimumSpan, (bounds.maxLongitude - bounds.minLongitude) * paddingFactor)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (bounds.minLatitude + bounds.maxLatitude) / 2,
                longitude: (bounds.minLongitude + bounds.maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: min(170, latitudeDelta),
                longitudeDelta: min(350, longitudeDelta)
            )
        )
    }
}
