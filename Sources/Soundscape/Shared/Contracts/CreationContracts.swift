import Foundation

struct TitleSuggestionRequest: Encodable, Sendable {
    let locationName: String
    let promptText: String
    let personalSocial: Double
    let memoryPresent: Double

    enum CodingKeys: String, CodingKey {
        case locationName = "location_name"
        case promptText = "prompt_text"
        case personalSocial = "tag_personal_social"
        case memoryPresent = "tag_memory_present"
    }
}

struct TitleSuggestion: Decodable, Equatable, Sendable {
    let title: String
    let description: String
}

struct CoverSuggestionRequest: Encodable, Sendable {
    let title: String
    let locationName: String
    let mood: String

    enum CodingKeys: String, CodingKey {
        case title, mood
        case locationName = "location_name"
    }
}

struct CoverSuggestion: Decodable, Equatable, Sendable {
    let coverURL: String
    let coverIsAI: Int

    enum CodingKeys: String, CodingKey {
        case coverURL = "cover_url"
        case coverIsAI = "cover_is_ai"
    }
}

struct MediaFile: Sendable, Equatable {
    let data: Data
    let filename: String
    let contentType: String
}

enum MediaConstraints {
    static let maximumAudioBytes = 50 * 1_024 * 1_024
    static let maximumCoverBytes = 12 * 1_024 * 1_024

    private static let supportedAudioTypes: Set<String> = [
        "audio/aac",
        "audio/m4a",
        "audio/mp4",
        "audio/mpeg",
        "audio/wav",
        "audio/x-m4a",
        "audio/x-wav"
    ]

    static func audio(data: Data, filename: String, contentType: String) throws -> MediaFile {
        try validateAudioByteCount(data.count)
        guard supportedAudioTypes.contains(contentType.lowercased()) else {
            throw AppError.invalidRequest(.loc(.errorSelectM4A))
        }
        return MediaFile(data: data, filename: filename, contentType: contentType)
    }

    static func cover(data: Data, filename: String = "cover.jpg", contentType: String = "image/jpeg") throws -> MediaFile {
        try validateCoverByteCount(data.count)
        guard !data.isEmpty else { throw AppError.invalidRequest(loc(.errorCoverEmpty)) }
        return MediaFile(data: data, filename: filename, contentType: contentType)
    }

    static func validateAudioByteCount(_ byteCount: Int) throws {
        guard byteCount > 0 else { throw AppError.invalidRequest(loc(.errorAudioEmpty)) }
        guard byteCount <= maximumAudioBytes else {
            throw AppError.invalidRequest(loc(.errorAudioTooLarge))
        }
    }

    static func validateCoverByteCount(_ byteCount: Int) throws {
        guard byteCount <= maximumCoverBytes else {
            throw AppError.invalidRequest(loc(.errorCoverTooLarge))
        }
    }
}

enum DraftConstraints {
    static let maximumTitleCharacters = 80
    static let maximumDescriptionCharacters = 500
    static let maximumLocationCharacters = 160

    static func validate(title: String, description: String, locationName: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw AppError.invalidRequest(loc(.errorTitleRequired)) }
        guard trimmedTitle.count <= maximumTitleCharacters else {
            throw AppError.invalidRequest(loc(.errorTitleTooLong))
        }
        guard description.count <= maximumDescriptionCharacters else {
            throw AppError.invalidRequest(loc(.errorDescriptionTooLong))
        }
        guard locationName.count <= maximumLocationCharacters else {
            throw AppError.invalidRequest(loc(.errorLocationNameTooLong))
        }
    }

    static func titleIsValid(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maximumTitleCharacters
    }
}

enum DraftCover: Sendable, Equatable {
    case upload(MediaFile)
    case generated(path: String)
}

struct CreateSoundscapeDraft: Sendable, Equatable {
    let audio: MediaFile
    let cover: DraftCover?
    let title: String
    let description: String
    let latitude: Double?
    let longitude: Double?
    let locationName: String
    let category: String
    let promptText: String
    let personalSocial: Double
    let memoryPresent: Double
    let isPublic: Bool
}

struct PlayResponse: Decodable, Equatable, Sendable {
    let ok: Bool
    let fullPlay: Bool

    enum CodingKeys: String, CodingKey {
        case ok
        case fullPlay = "full_play"
    }
}

struct SaveResponse: Decodable, Equatable, Sendable {
    let saved: Bool
    let saveCount: Int

    enum CodingKeys: String, CodingKey {
        case saved
        case saveCount = "save_count"
    }
}

struct MutationResponse: Decodable, Equatable, Sendable {
    let ok: Bool
}
