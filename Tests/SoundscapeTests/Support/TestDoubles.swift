import Foundation
@testable import Soundscape

actor InMemoryTokenStore: AuthTokenStore {
    private var value: String?

    init(token: String? = nil) { value = token }
    func token() async throws -> String? { value }
    func setToken(_ token: String) async throws { value = token }
    func clear() async throws { value = nil }
}

actor FailingTokenStore: AuthTokenStore {
    private let error: AppError

    init(error: AppError) { self.error = error }
    func token() async throws -> String? { throw error }
    func setToken(_ token: String) async throws { throw error }
    func clear() async throws { throw error }
}

actor InMemoryResonanceStateStore: ResonanceStatePersisting {
    private var state: ResonancePersonalizationState?

    init(state: ResonancePersonalizationState? = nil) {
        self.state = state
    }

    func load() async throws -> ResonancePersonalizationState? { state }
    func save(_ state: ResonancePersonalizationState) async throws { self.state = state }
    func reset() async throws { state = nil }
    func snapshot() -> ResonancePersonalizationState? { state }
}

actor StubResonanceMatchingService: ResonanceMatching {
    var recommendationResult: Result<RecommendationBatch, AppError>?
    private(set) var impressions: [RecommendationImpression] = []
    private(set) var feedback: [RecommendationFeedbackRecord] = []
    private(set) var resetCount = 0

    func setRecommendationResult(_ result: Result<RecommendationBatch, AppError>) {
        recommendationResult = result
    }

    func recommendations(for request: ResonanceRequest, limit: Int) async throws -> RecommendationBatch {
        guard let recommendationResult else { throw AppError.invalidRequest("missing recommendation stub") }
        return try recommendationResult.get()
    }

    func returningRecommendations(limit: Int) async throws -> RecommendationBatch {
        guard let recommendationResult else { throw AppError.invalidRequest("missing recommendation stub") }
        return try recommendationResult.get()
    }

    func recordImpressions(_ impressions: [RecommendationImpression]) async throws {
        self.impressions.append(contentsOf: impressions)
    }

    func recordFeedback(
        _ feedback: ResonanceFeedback,
        for soundscape: Soundscape,
        context: RecommendationContext
    ) async throws {
        self.feedback.append(RecommendationFeedbackRecord(
            context: context,
            feedback: feedback,
            recordedAt: Date(timeIntervalSince1970: 10)
        ))
    }

    func resetPersonalization() async throws { resetCount += 1 }
}

actor StubHTTPTransport: HTTPTransport {
    struct Stub: Sendable {
        let data: Data
        let status: Int
        var error: AppError?

        init(data: Data, status: Int, error: AppError? = nil) {
            self.data = data
            self.status = status
            self.error = error
        }

        static func failure(_ error: AppError) -> Stub {
            Stub(data: Data(), status: 0, error: error)
        }
    }

    private var stubs: [Stub]
    private(set) var requests: [URLRequest] = []

    init(stubs: [Stub]) { self.stubs = stubs }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard !stubs.isEmpty else { throw AppError.transport("missing stub") }
        let stub = stubs.removeFirst()
        if let error = stub.error { throw error }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stub.status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (stub.data, response)
    }
}

actor StubSoundscapeRepository: SoundscapeRepository {
    var exploreResult: Result<[Soundscape], AppError> = .success([])
    var rankingResult: Result<[RankingLane], AppError> = .success([])
    var mineResult: Result<[Soundscape], AppError> = .success([])
    var createdDraft: CreateSoundscapeDraft?
    var reportedPlays: [(id: Int, listenedSeconds: Int)] = []
    var reportPlayResult: Result<PlayResponse, AppError> = .success(PlayResponse(ok: true, fullPlay: false))
    var visibilityResult: Result<Void, AppError> = .success(())
    var deleteResult: Result<Void, AppError> = .success(())
    var visibilityCalls: [(id: Int, isPublic: Bool)] = []
    var deletedIDs: [Int] = []
    private(set) var exploreCallCount = 0
    private(set) var explorePolicies: [RepositoryReadPolicy] = []
    private(set) var rankingCallCount = 0
    private var exploreDelay: Duration?
    private var mineDelay: Duration?

    func setExploreResult(_ result: Result<[Soundscape], AppError>) { exploreResult = result }
    func setExploreDelay(_ delay: Duration?) { exploreDelay = delay }
    func setMineDelay(_ delay: Duration?) { mineDelay = delay }
    func setRankingResult(_ result: Result<[RankingLane], AppError>) { rankingResult = result }
    func setMineResult(_ result: Result<[Soundscape], AppError>) { mineResult = result }
    func setReportPlayResult(_ result: Result<PlayResponse, AppError>) { reportPlayResult = result }
    func setVisibilityResult(_ result: Result<Void, AppError>) { visibilityResult = result }
    func setDeleteResult(_ result: Result<Void, AppError>) { deleteResult = result }
    func explore(category: String?, policy: RepositoryReadPolicy) async throws -> [Soundscape] {
        exploreCallCount += 1
        explorePolicies.append(policy)
        if let exploreDelay { try await Task.sleep(for: exploreDelay) }
        return try exploreResult.get()
    }
    func rankings(policy: RepositoryReadPolicy) async throws -> [RankingLane] {
        rankingCallCount += 1
        return try rankingResult.get()
    }
    nonisolated func mine() async throws -> [Soundscape] {
        if let delay = await pendingMineDelay() {
            try await Task.sleep(for: delay)
        }
        return try await currentMine()
    }

    private func pendingMineDelay() -> Duration? { mineDelay }
    private func currentMine() throws -> [Soundscape] { try mineResult.get() }
    func create(_ draft: CreateSoundscapeDraft) async throws -> Soundscape {
        createdDraft = draft
        return TestFixtures.soundscape
    }
    func suggestTitle(_ request: TitleSuggestionRequest) async throws -> TitleSuggestion {
        TitleSuggestion(title: "雨落站台", description: "列车离开后，雨声留在空站台。")
    }
    func suggestCover(_ request: CoverSuggestionRequest) async throws -> CoverSuggestion {
        CoverSuggestion(coverURL: "/soundscape/uploads/covers/generated.png", coverIsAI: 1)
    }
    func reportPlay(id: Int, listenedSeconds: Int) async throws -> PlayResponse {
        reportedPlays.append((id, listenedSeconds))
        return try reportPlayResult.get()
    }
    func toggleSave(id: Int) async throws -> SaveResponse { SaveResponse(saved: true, saveCount: 3) }
    func setVisibility(id: Int, isPublic: Bool) async throws {
        visibilityCalls.append((id, isPublic))
        try visibilityResult.get()
    }
    func delete(id: Int) async throws {
        deletedIDs.append(id)
        try deleteResult.get()
    }
}

actor StubIdentityRepository: IdentityRepository {
    var currentUserResult: Result<PanorUser?, AppError> = .success(nil)
    var loginResult: Result<PanorUser, AppError> = .success(PanorUser(
        id: "u_2",
        name: "wilson",
        email: "wilson@example.com",
        picture: nil
    ))
    var registerResult: Result<PanorUser, AppError> = .success(PanorUser(
        id: "u_3",
        name: "new-user",
        email: "new-user@example.com",
        picture: nil
    ))
    var logoutResult: Result<Void, AppError> = .success(())
    private(set) var registrationCredentials: RegistrationCredentials?

    func setCurrentUserResult(_ result: Result<PanorUser?, AppError>) { currentUserResult = result }
    func setLogoutResult(_ result: Result<Void, AppError>) { logoutResult = result }
    func register(credentials: RegistrationCredentials) async throws -> PanorUser {
        registrationCredentials = credentials
        return try registerResult.get()
    }
    func login(credentials: LoginCredentials) async throws -> PanorUser { try loginResult.get() }
    func googleLogin(idToken: String) async throws -> PanorUser { try loginResult.get() }
    func appleLogin(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?) async throws -> PanorUser { try loginResult.get() }
    func currentUser() async throws -> PanorUser? { try currentUserResult.get() }
    func logout() async throws { try logoutResult.get() }
}

@MainActor
final class StubAudioPlaybackEngine: AudioPlaybackEngine {
    var onProgress: ((Double, Double?) -> Void)?
    var onStateChanged: ((AudioPlaybackEngineState) -> Void)?
    var onEnded: (() -> Void)?
    var onFailure: ((AppError) -> Void)?
    private(set) var loadedURLs: [URL] = []
    private(set) var playCount = 0
    private(set) var restartCount = 0
    private(set) var pauseCount = 0
    private(set) var stopCount = 0
    private(set) var volumeChanges: [(volume: Float, duration: TimeInterval)] = []

    func load(url: URL) throws {
        loadedURLs.append(url)
        onStateChanged?(.loading)
    }
    func play() throws { playCount += 1 }
    func restart() throws {
        restartCount += 1
        onStateChanged?(.playing)
    }
    func pause() { pauseCount += 1 }
    func stop() { stopCount += 1 }
    func setVolume(_ volume: Float, duration: TimeInterval) {
        volumeChanges.append((volume, duration))
    }
    func startPlaying() { onStateChanged?(.playing) }
    func progress(elapsed: Double, duration: Double?) { onProgress?(elapsed, duration) }
    func finish() { onEnded?() }
    func fail(_ error: AppError) { onFailure?(error) }
}

@MainActor
final class StubPlaybackAudioSession: PlaybackAudioSession {
    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: ((Bool) -> Void)?
    var onOutputRouteLost: (() -> Void)?
    private(set) var activationCount = 0
    private(set) var deactivationCount = 0
    var suspendActivation = false
    var suspendDeactivation = false
    private var activationContinuation: CheckedContinuation<Void, Never>?
    private var deactivationContinuation: CheckedContinuation<Void, Never>?

    func activate() async throws {
        activationCount += 1
        if suspendActivation {
            await withCheckedContinuation { continuation in
                activationContinuation = continuation
            }
        }
    }
    func deactivate() async throws {
        deactivationCount += 1
        if suspendDeactivation {
            await withCheckedContinuation { continuation in
                deactivationContinuation = continuation
            }
        }
    }
    func finishActivation() {
        activationContinuation?.resume()
        activationContinuation = nil
    }
    func finishDeactivation() {
        deactivationContinuation?.resume()
        deactivationContinuation = nil
    }
    func interrupt() { onInterruptionBegan?() }
    func endInterruption(shouldResume: Bool) { onInterruptionEnded?(shouldResume) }
    func loseOutputRoute() { onOutputRouteLost?() }
}

enum TestFixtures {
    static let soundscape = Soundscape(
        id: 17,
        ownerID: "2",
        authorName: "wilsonxu",
        title: "九巷风藏旧语声",
        description: "烟火声响里裹着旧念。",
        audioURL: URL(string: "https://www.panor.tech/soundscape/uploads/audio/sample.m4a"),
        coverURL: URL(string: "https://www.panor.tech/soundscape/uploads/covers/sample.png"),
        coverIsAI: true,
        latitude: 22.579,
        longitude: 113.861,
        locationName: "Bao'an District · 盐田新一村九巷",
        category: "地方",
        promptText: "录下一段让你想起某个人的声音",
        personalSocial: 0.5,
        memoryPresent: 0.5,
        durationSeconds: 699,
        isPublic: true,
        playCount: 2,
        fullPlayCount: 0,
        saveCount: 0,
        createdAt: "2026-07-17 13:51:30"
    )

    static let soundscapeWithoutCoordinate = Soundscape(
        id: 18,
        ownerID: "2",
        authorName: "wilsonxu",
        title: "无坐标声景",
        description: "仅用于筛选测试。",
        audioURL: URL(string: "https://www.panor.tech/soundscape/uploads/audio/no-coordinate.m4a"),
        coverURL: nil,
        coverIsAI: false,
        latitude: nil,
        longitude: nil,
        locationName: "",
        category: "自然",
        promptText: "",
        personalSocial: 0.5,
        memoryPresent: 0.5,
        durationSeconds: 20,
        isPublic: false,
        playCount: 0,
        fullPlayCount: 0,
        saveCount: 0,
        createdAt: "2026-07-18 08:00:00"
    )
}
