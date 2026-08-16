import Foundation

protocol SoundscapeRepository: Sendable {
    func explore(category: String?, policy: RepositoryReadPolicy) async throws -> [Soundscape]
    func rankings(policy: RepositoryReadPolicy) async throws -> [RankingLane]
    func mine() async throws -> [Soundscape]
    func create(_ draft: CreateSoundscapeDraft) async throws -> Soundscape
    func suggestTitle(_ request: TitleSuggestionRequest) async throws -> TitleSuggestion
    func suggestCover(_ request: CoverSuggestionRequest) async throws -> CoverSuggestion
    func reportPlay(id: Int, listenedSeconds: Int) async throws -> PlayResponse
    func toggleSave(id: Int) async throws -> SaveResponse
    func setVisibility(id: Int, isPublic: Bool) async throws
    func delete(id: Int) async throws
}

enum RepositoryReadPolicy: Sendable {
    case cacheFirst
    case reloadIgnoringCache
}

extension SoundscapeRepository {
    func explore(category: String?) async throws -> [Soundscape] {
        try await explore(category: category, policy: .cacheFirst)
    }

    func rankings() async throws -> [RankingLane] {
        try await rankings(policy: .cacheFirst)
    }
}

enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(AppError)
}

enum AppError: Error, Equatable, Sendable {
    case authenticationRequired
    case invalidRequest(String)
    case transport(String)
    case server(status: Int, code: String?, message: String)
    case decoding
    case secureStorageUnavailable(status: Int32)
    case registrationCompletedButSessionUnavailable
    case audioPlaybackUnavailable
    case microphonePermissionDenied
    case recordingUnavailable
    case locationUnavailable
    case personalizationUnavailable

    var userMessage: String {
        switch self {
        case .authenticationRequired: loc(.errorLoginRequired)
        case .invalidRequest(let message): message
        case .transport: loc(.errorNetworkUnavailable)
        case .server(_, let code, _):
            switch code {
            case "ai_title_unavailable": loc(.errorTitleGenerationFailed)
            case "ai_cover_unavailable": loc(.errorCoverGenerationFailed)
            default: loc(.errorServerFailed)
            }
        case .decoding: loc(.errorServerDataUnrecognized)
        case .secureStorageUnavailable: loc(.errorKeychainFailed)
        case .registrationCompletedButSessionUnavailable: loc(.errorAccountCreatedButCantSave)
        case .audioPlaybackUnavailable: loc(.errorAudioPlaybackUnavailable)
        case .microphonePermissionDenied: loc(.errorMicPermission)
        case .recordingUnavailable: loc(.errorRecordingFailed)
        case .locationUnavailable: "\(loc(.errorLocationUnavailable)) \(loc(.errorLocationUnavailableCanPublish))"
        case .personalizationUnavailable: loc(.errorPersonalizationUnavailable)
        }
    }
}
