import Foundation

actor LocalResonanceMatchingService: ResonanceMatching {
    private let repository: any SoundscapeRepository
    private let store: any ResonanceStatePersisting
    private let featureProvider: any SoundscapeFeatureProviding
    private let matcher: ResonanceMatcher
    private let now: @Sendable () -> Date
    private let sessionTimeout: TimeInterval
    private let maximumEventCount: Int

    init(
        repository: any SoundscapeRepository,
        store: any ResonanceStatePersisting,
        featureProvider: any SoundscapeFeatureProviding = MetadataSoundscapeFeatureProvider(),
        configuration: ResonanceMatchingConfiguration = ResonanceMatchingConfiguration(),
        now: @escaping @Sendable () -> Date = Date.init,
        sessionTimeout: TimeInterval = 6 * 60 * 60,
        maximumEventCount: Int = 500
    ) {
        self.repository = repository
        self.store = store
        self.featureProvider = featureProvider
        matcher = ResonanceMatcher(featureProvider: featureProvider, configuration: configuration)
        self.now = now
        self.sessionTimeout = sessionTimeout
        self.maximumEventCount = max(1, maximumEventCount)
    }

    func recommendations(for request: ResonanceRequest, limit: Int) async throws -> RecommendationBatch {
        let date = now()
        var state = try await loadedState()
        state.profile.expireSessionIfNeeded(now: date, timeout: sessionTimeout)
        state.profile.incorporate(request: request, at: date)
        let candidates = try await repository.explore(category: nil, policy: .cacheFirst)
        let items = matcher.rank(candidates, request: request, profile: state.profile, limit: limit)
        guard !items.isEmpty else { throw AppError.invalidRequest(loc(.errorNoPlayableReady)) }
        try await store.save(state)
        return RecommendationBatch(
            request: request,
            sessionID: state.profile.sessionID,
            modelVersion: matcher.configuration.modelVersion,
            candidateCount: candidates.count,
            items: items
        )
    }

    func returningRecommendations(limit: Int) async throws -> RecommendationBatch {
        let date = now()
        var state = try await loadedState()
        state.profile.expireSessionIfNeeded(now: date, timeout: sessionTimeout)
        let request = ResonanceRequest(
            mode: state.profile.lastMode ?? .discover,
            confidence: state.profile.longTerm == nil && state.profile.session == nil ? 0.2 : 0.45,
            requestedAt: date
        )
        return try await recommendations(for: request, limit: limit)
    }

    func recordImpressions(_ impressions: [RecommendationImpression]) async throws {
        guard !impressions.isEmpty else { return }
        var state = try await loadedState()
        var existingKeys = Set(state.impressions.map(Self.impressionKey))
        for impression in impressions {
            let key = Self.impressionKey(impression)
            guard existingKeys.insert(key).inserted else { continue }
            state.impressions.append(impression)
            state.profile.recordExposure(
                soundscapeID: impression.context.soundscapeID,
                at: impression.shownAt
            )
        }
        state.impressions = Array(state.impressions.suffix(maximumEventCount))
        try await store.save(state)
    }

    func recordFeedback(
        _ feedback: ResonanceFeedback,
        for soundscape: Soundscape,
        context: RecommendationContext
    ) async throws {
        guard context.soundscapeID == soundscape.id else {
            throw AppError.invalidRequest(loc(.errorPersonalizationUnavailable))
        }
        let date = now()
        var state = try await loadedState()
        state.profile.expireSessionIfNeeded(now: date, timeout: sessionTimeout)
        state.profile.apply(
            feedback,
            content: featureProvider.features(for: soundscape).collectivePerception,
            mode: context.mode,
            at: date
        )
        state.feedback.append(RecommendationFeedbackRecord(
            context: context,
            feedback: feedback,
            recordedAt: date
        ))
        state.feedback = Array(state.feedback.suffix(maximumEventCount))
        try await store.save(state)
    }

    func resetPersonalization() async throws {
        try await store.reset()
    }

    private func loadedState() async throws -> ResonancePersonalizationState {
        try await store.load() ?? .empty
    }

    private static func impressionKey(_ impression: RecommendationImpression) -> String {
        "\(impression.context.requestID.uuidString):\(impression.context.soundscapeID)"
    }
}
