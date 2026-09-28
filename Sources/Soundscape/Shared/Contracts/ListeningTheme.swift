import Foundation

struct ListeningTheme: Codable, Hashable, Identifiable, Sendable {
    enum Kind: String, Codable, CaseIterable, Sendable { case topic, event }
    let id: Int
    let title: String
    let description: String
    let kind: Kind
    let startsOn: String?
    let endsOn: String?
    let recordingCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, kind
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case recordingCount = "recording_count"
    }
}

struct ListeningThemeDraft: Encodable, Sendable {
    let title: String
    let description: String
    let kind: ListeningTheme.Kind
    let startsOn: String?
    let endsOn: String?

    enum CodingKeys: String, CodingKey {
        case title, description, kind
        case startsOn = "starts_on"
        case endsOn = "ends_on"
    }
}

/// A geographic filter independent of MapKit and testable at ±180° longitude.
struct RecordingMapArea: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double

    func contains(latitude lat: Double, longitude lon: Double) -> Bool {
        guard lat.isFinite, lon.isFinite, (-90...90).contains(lat), (-180...180).contains(lon) else { return false }
        let difference = abs(lon - longitude).truncatingRemainder(dividingBy: 360)
        let wrapped = min(difference, 360 - difference)
        return abs(lat - latitude) <= latitudeDelta / 2 && wrapped <= longitudeDelta / 2
    }
}
