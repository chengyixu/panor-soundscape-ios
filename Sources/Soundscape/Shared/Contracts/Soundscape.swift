import Foundation

struct Soundscape: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let ownerID: String
    let authorName: String
    let title: String
    let description: String
    let audioURL: URL?
    let coverURL: URL?
    let coverIsAI: Bool
    let latitude: Double?
    let longitude: Double?
    let locationName: String
    let category: String
    let promptText: String
    let personalSocial: Double
    let memoryPresent: Double
    let durationSeconds: Int
    let isPublic: Bool
    var moderationStatus: String = "approved"
    let playCount: Int
    let fullPlayCount: Int
    let saveCount: Int
    let createdAt: String
    var world: WorldManifest = .pending

    var hasCoordinate: Bool { latitude != nil && longitude != nil }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? loc(.unnamedSoundscape) : title
    }

    var locationDisplay: String {
        locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? loc(.unknownLocation) : locationName
    }

    var authorDisplay: String {
        let normalized = authorName.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? ownerID : normalized
    }

    var durationDisplay: String {
        let seconds = max(0, durationSeconds)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

enum WorldStatus: String, Codable, Hashable, Sendable {
    case queued
    case preparing
    case awaitingGaussian = "awaiting_gaussian"
    case generating
    case ready
    case failed

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = WorldStatus(rawValue: value) ?? .failed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct WorldAsset: Codable, Hashable, Sendable {
    let url: URL
    let format: String
    let sha256: String
    let bytes: Int
}

struct WorldAssets: Codable, Hashable, Sendable {
    let preview: WorldAsset
    let standard: WorldAsset
}

struct WorldManifest: Codable, Hashable, Sendable {
    let status: WorldStatus
    let format: String
    let provenance: String
    let updatedAt: String?
    let assets: WorldAssets?

    static let pending = WorldManifest(
        status: .queued,
        format: "spz",
        provenance: "ai_gaussian",
        updatedAt: nil,
        assets: nil
    )

    enum CodingKeys: String, CodingKey {
        case status, format, provenance, assets
        case updatedAt = "updated_at"
    }
}

struct RankingLane: Codable, Identifiable, Hashable, Sendable {
    var id: String { category }
    let category: String
    let items: [Soundscape]
}

struct SoundscapeDTO: Decodable, Sendable {
    let id: Int
    let userID: String?
    let authorName: String?
    let title: String?
    let description: String?
    let audioURL: String?
    let coverURL: String?
    let coverIsAI: Int?
    let lat: Double?
    let lng: Double?
    let locationName: String?
    let category: String?
    let promptText: String?
    let tagPersonalSocial: Double?
    let tagMemoryPresent: Double?
    let durationSec: Int?
    let isPublic: Int?
    let moderationStatus: String?
    let playCount: Int?
    let fullPlayCount: Int?
    let saveCount: Int?
    let createdAt: String?
    let world: WorldManifestDTO?

    enum CodingKeys: String, CodingKey {
        case id, title, description, lat, lng, category, world
        case userID = "user_id"
        case authorName = "author_name"
        case audioURL = "audio_url"
        case coverURL = "cover_url"
        case coverIsAI = "cover_is_ai"
        case locationName = "location_name"
        case promptText = "prompt_text"
        case tagPersonalSocial = "tag_personal_social"
        case tagMemoryPresent = "tag_memory_present"
        case durationSec = "duration_sec"
        case isPublic = "is_public"
        case moderationStatus = "moderation_status"
        case playCount = "play_count"
        case fullPlayCount = "full_play_count"
        case saveCount = "save_count"
        case createdAt = "created_at"
    }

    func domain(environment: APIEnvironment) -> Soundscape {
        var value = Soundscape(
            id: id,
            ownerID: userID ?? "",
            authorName: authorName ?? userID ?? "",
            title: title ?? "",
            description: description ?? "",
            audioURL: environment.mediaURL(for: audioURL),
            coverURL: environment.mediaURL(for: coverURL),
            coverIsAI: coverIsAI == 1,
            latitude: lat,
            longitude: lng,
            locationName: locationName ?? "",
            category: category ?? SoundscapeCategory.soundscape.rawValue,
            promptText: promptText ?? "",
            personalSocial: tagPersonalSocial ?? 0.5,
            memoryPresent: tagMemoryPresent ?? 0.5,
            durationSeconds: durationSec ?? 0,
            isPublic: isPublic != 0,
            playCount: playCount ?? 0,
            fullPlayCount: fullPlayCount ?? 0,
            saveCount: saveCount ?? 0,
            createdAt: createdAt ?? ""
        )
        value.moderationStatus = moderationStatus ?? "approved"
        value.world = world?.domain(environment: environment) ?? .pending
        return value
    }
}

struct WorldAssetDTO: Decodable, Sendable {
    let url: String
    let format: String
    let sha256: String
    let bytes: Int

    func domain(environment: APIEnvironment) -> WorldAsset? {
        guard format == "spz", let resolvedURL = environment.mediaURL(for: url) else { return nil }
        return WorldAsset(url: resolvedURL, format: format, sha256: sha256, bytes: bytes)
    }
}

struct WorldAssetsDTO: Decodable, Sendable {
    let preview: WorldAssetDTO
    let standard: WorldAssetDTO
}

struct WorldManifestDTO: Decodable, Sendable {
    let status: WorldStatus
    let format: String
    let provenance: String
    let updatedAt: String?
    let assets: WorldAssetsDTO?

    enum CodingKeys: String, CodingKey {
        case status, format, provenance, assets
        case updatedAt = "updated_at"
    }

    func domain(environment: APIEnvironment) -> WorldManifest {
        guard format == "spz", provenance == "ai_gaussian" else { return .pending }
        let resolvedAssets: WorldAssets?
        if let assets,
           let preview = assets.preview.domain(environment: environment),
           let standard = assets.standard.domain(environment: environment) {
            resolvedAssets = WorldAssets(preview: preview, standard: standard)
        } else {
            resolvedAssets = nil
        }
        return WorldManifest(
            status: status == .ready && resolvedAssets == nil ? .failed : status,
            format: format,
            provenance: provenance,
            updatedAt: updatedAt,
            assets: resolvedAssets
        )
    }
}

struct RankingLaneDTO: Decodable, Sendable {
    let category: String
    let items: [SoundscapeDTO]
}
