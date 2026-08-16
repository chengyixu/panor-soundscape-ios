import Foundation

enum ResonanceMode: String, Codable, CaseIterable, Hashable, Sendable {
    case mirror
    case shift
    case escape
    case focus
    case recall
    case discover
}

struct AffectState: Codable, Equatable, Sendable {
    let pleasantness: Double
    let arousal: Double

    init(pleasantness: Double, arousal: Double) {
        self.pleasantness = pleasantness.clampedUnit
        self.arousal = arousal.clampedUnit
    }
}

struct CoarseLocation: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

enum ResonanceAvoidance: String, Codable, Hashable, Sendable {
    case speech
    case suddenNoise
    case highArousal
    case urban
    case nature
}

enum ResonanceInputProvenance: String, Codable, Hashable, Sendable {
    case goal
    case text
    case recording
    case speechTranscript
    case environmentAudio
    case pairwiseCalibration
}

struct ResonanceInput: Equatable, Sendable {
    let text: String
    let provenance: Set<ResonanceInputProvenance>

    init(text: String, provenance: Set<ResonanceInputProvenance>) {
        self.text = text
        self.provenance = provenance
    }
}

struct ResonanceRequest: Codable, Equatable, Sendable {
    let id: UUID
    let mode: ResonanceMode
    let queryText: String
    let currentState: AffectState?
    let targetState: AffectState?
    let location: CoarseLocation?
    let avoidances: Set<ResonanceAvoidance>
    let inputProvenance: Set<ResonanceInputProvenance>
    let confidence: Double
    let allowsMemoryAnchors: Bool
    let requestedAt: Date

    init(
        id: UUID = UUID(),
        mode: ResonanceMode,
        queryText: String = "",
        currentState: AffectState? = nil,
        targetState: AffectState? = nil,
        location: CoarseLocation? = nil,
        avoidances: Set<ResonanceAvoidance> = [],
        inputProvenance: Set<ResonanceInputProvenance> = [],
        confidence: Double = 0.5,
        allowsMemoryAnchors: Bool = false,
        requestedAt: Date = Date()
    ) {
        self.id = id
        self.mode = mode
        self.queryText = queryText
        self.currentState = currentState
        self.targetState = targetState
        self.location = location
        self.avoidances = avoidances
        self.inputProvenance = inputProvenance
        self.confidence = confidence.clampedUnit
        self.allowsMemoryAnchors = allowsMemoryAnchors
        self.requestedAt = requestedAt
    }
}

struct ResonanceVector: Codable, Equatable, Sendable {
    var pleasantness: Double
    var arousal: Double
    var social: Double
    var memory: Double
    var nature: Double
    var urban: Double
    var focus: Double
    var intimacy: Double

    init(
        pleasantness: Double = 0.5,
        arousal: Double = 0.5,
        social: Double = 0.5,
        memory: Double = 0.5,
        nature: Double = 0.5,
        urban: Double = 0.5,
        focus: Double = 0.5,
        intimacy: Double = 0.5
    ) {
        self.pleasantness = pleasantness.clampedUnit
        self.arousal = arousal.clampedUnit
        self.social = social.clampedUnit
        self.memory = memory.clampedUnit
        self.nature = nature.clampedUnit
        self.urban = urban.clampedUnit
        self.focus = focus.clampedUnit
        self.intimacy = intimacy.clampedUnit
    }

    static let neutral = ResonanceVector()
    static let calm = ResonanceVector(
        pleasantness: 0.75,
        arousal: 0.2,
        social: 0.3,
        memory: 0.35,
        nature: 0.65,
        urban: 0.25,
        focus: 0.75,
        intimacy: 0.55
    )
    static let calmNature = ResonanceVector(
        pleasantness: 0.8,
        arousal: 0.18,
        social: 0.18,
        memory: 0.45,
        nature: 0.95,
        urban: 0.05,
        focus: 0.78,
        intimacy: 0.62
    )
    static let calmUrban = ResonanceVector(
        pleasantness: 0.68,
        arousal: 0.3,
        social: 0.45,
        memory: 0.42,
        nature: 0.08,
        urban: 0.92,
        focus: 0.64,
        intimacy: 0.48
    )
    static let highEnergyUrban = ResonanceVector(
        pleasantness: 0.48,
        arousal: 0.92,
        social: 0.85,
        memory: 0.25,
        nature: 0.05,
        urban: 0.98,
        focus: 0.18,
        intimacy: 0.15
    )

    func similarity(to other: ResonanceVector) -> Double {
        let differences = zip(values, other.values).map { lhs, rhs in
            let difference = lhs - rhs
            return difference * difference
        }
        let distance = sqrt(differences.reduce(0, +) / Double(differences.count))
        return (1 - distance).clampedUnit
    }

    func blended(toward other: ResonanceVector, rate: Double) -> ResonanceVector {
        let amount = rate.clampedUnit
        return ResonanceVector(
            pleasantness: pleasantness + (other.pleasantness - pleasantness) * amount,
            arousal: arousal + (other.arousal - arousal) * amount,
            social: social + (other.social - social) * amount,
            memory: memory + (other.memory - memory) * amount,
            nature: nature + (other.nature - nature) * amount,
            urban: urban + (other.urban - urban) * amount,
            focus: focus + (other.focus - focus) * amount,
            intimacy: intimacy + (other.intimacy - intimacy) * amount
        )
    }

    var opposed: ResonanceVector {
        ResonanceVector(
            pleasantness: 1 - pleasantness,
            arousal: 1 - arousal,
            social: 1 - social,
            memory: 1 - memory,
            nature: 1 - nature,
            urban: 1 - urban,
            focus: 1 - focus,
            intimacy: 1 - intimacy
        )
    }

    private var values: [Double] {
        [pleasantness, arousal, social, memory, nature, urban, focus, intimacy]
    }
}

enum ResonanceFeedbackKind: String, Codable, Hashable, Sendable {
    case started
    case advanced
    case completed
    case saved
    case replayed
    case resonated
    case goalReached
    case skipped
}

enum ResonanceFeedbackReason: String, Codable, Hashable, Sendable {
    case notNow
    case tooIntense
    case dislike
    case wrongPlace
    case uncomfortableMemory
}

struct ResonanceFeedback: Codable, Equatable, Sendable {
    let kind: ResonanceFeedbackKind
    let reason: ResonanceFeedbackReason?
    let listenedSeconds: Int

    init(
        kind: ResonanceFeedbackKind,
        reason: ResonanceFeedbackReason? = nil,
        listenedSeconds: Int = 0
    ) {
        self.kind = kind
        self.reason = reason
        self.listenedSeconds = max(0, listenedSeconds)
    }
}

struct ResonanceProfile: Codable, Equatable, Sendable {
    var longTerm: ResonanceVector?
    var session: ResonanceVector?
    var longTermObservations: Int
    var sessionObservations: Int
    var blockedSoundscapeIDs: Set<Int>
    var recentlyExposedSoundscapeIDs: [Int]
    var lastMode: ResonanceMode?
    var sessionID: UUID
    var lastSessionActivityAt: Date?

    init(
        longTerm: ResonanceVector? = nil,
        session: ResonanceVector? = nil,
        longTermObservations: Int = 0,
        sessionObservations: Int = 0,
        blockedSoundscapeIDs: Set<Int> = [],
        recentlyExposedSoundscapeIDs: [Int] = [],
        lastMode: ResonanceMode? = nil,
        sessionID: UUID = UUID(),
        lastSessionActivityAt: Date? = nil
    ) {
        self.longTerm = longTerm
        self.session = session
        self.longTermObservations = max(0, longTermObservations)
        self.sessionObservations = max(0, sessionObservations)
        self.blockedSoundscapeIDs = blockedSoundscapeIDs
        self.recentlyExposedSoundscapeIDs = recentlyExposedSoundscapeIDs
        self.lastMode = lastMode
        self.sessionID = sessionID
        self.lastSessionActivityAt = lastSessionActivityAt
    }

    static var empty: ResonanceProfile { ResonanceProfile() }

    mutating func apply(
        _ feedback: ResonanceFeedback,
        content: ResonanceVector,
        mode: ResonanceMode,
        at date: Date
    ) {
        let rewards = feedback.rewards(for: mode)
        if rewards.session != 0 {
            let target = rewards.session > 0 ? content : content.opposed
            let rate = min(0.62, 0.18 + abs(rewards.session) * 0.34)
            session = (session ?? .neutral).blended(toward: target, rate: rate)
            sessionObservations += 1
        }
        if rewards.longTerm != 0 {
            let target = rewards.longTerm > 0 ? content : content.opposed
            let rate = min(0.18, 0.025 + abs(rewards.longTerm) * 0.1)
            longTerm = (longTerm ?? .neutral).blended(toward: target, rate: rate)
            longTermObservations += 1
        }
        lastMode = mode
        lastSessionActivityAt = date
    }

    mutating func incorporate(request: ResonanceRequest, at date: Date) {
        let target = request.preferenceVector
        let rate = 0.35 + request.confidence * 0.35
        session = (session ?? .neutral).blended(toward: target, rate: rate)
        sessionObservations += 1
        lastMode = request.mode
        lastSessionActivityAt = date
    }

    mutating func recordExposure(soundscapeID: Int, at date: Date, maximumCount: Int = 12) {
        recentlyExposedSoundscapeIDs.removeAll { $0 == soundscapeID }
        recentlyExposedSoundscapeIDs.append(soundscapeID)
        if recentlyExposedSoundscapeIDs.count > maximumCount {
            recentlyExposedSoundscapeIDs.removeFirst(recentlyExposedSoundscapeIDs.count - maximumCount)
        }
        lastSessionActivityAt = date
    }

    mutating func expireSessionIfNeeded(now: Date, timeout: TimeInterval) {
        guard let lastSessionActivityAt,
              now.timeIntervalSince(lastSessionActivityAt) > timeout else { return }
        session = nil
        sessionObservations = 0
        recentlyExposedSoundscapeIDs = []
        sessionID = UUID()
        self.lastSessionActivityAt = now
    }
}

struct SoundscapeMatchingFeatures: Equatable, Sendable {
    let creatorIntent: ResonanceVector
    let collectivePerception: ResonanceVector
    let creatorIntentText: String
    let collectiveText: String
    let editorialQuality: Double
    let novelty: Double
    let suddenNoiseRisk: Double
    let loopStability: Double

    init(
        creatorIntent: ResonanceVector = .neutral,
        collectivePerception: ResonanceVector = .neutral,
        creatorIntentText: String = "",
        collectiveText: String = "",
        editorialQuality: Double = 0.5,
        novelty: Double = 0.5,
        suddenNoiseRisk: Double = 0.5,
        loopStability: Double = 0.5
    ) {
        self.creatorIntent = creatorIntent
        self.collectivePerception = collectivePerception
        self.creatorIntentText = creatorIntentText
        self.collectiveText = collectiveText
        self.editorialQuality = editorialQuality.clampedUnit
        self.novelty = novelty.clampedUnit
        self.suddenNoiseRisk = suddenNoiseRisk.clampedUnit
        self.loopStability = loopStability.clampedUnit
    }
}

protocol SoundscapeFeatureProviding: Sendable {
    func features(for soundscape: Soundscape) -> SoundscapeMatchingFeatures
}

enum RecommendationCandidateSource: String, Codable, Equatable, Sendable {
    case intent
    case collective
    case session
    case longTerm
    case memory
    case geographic
    case editorial
    case exploration
}

enum RecommendationRole: String, Codable, Equatable, Sendable {
    case closest
    case alternate
    case surprise
    case stream
}

struct RecommendationScore: Codable, Equatable, Sendable {
    let creatorIntent: Double
    let collectivePerception: Double
    let explicitArousal: Double
    let sessionArousal: Double
    let longTermArousal: Double
    let userArousal: Double
    let geographicFit: Double
    let novelty: Double
    let repetitionPenalty: Double
    let riskPenalty: Double
    let total: Double
}

struct MatchedSoundscape: Equatable, Sendable {
    let soundscape: Soundscape
    let role: RecommendationRole
    let source: RecommendationCandidateSource
    let score: RecommendationScore
    let featureVector: ResonanceVector
}

struct RecommendationContext: Codable, Equatable, Sendable {
    let requestID: UUID
    let sessionID: UUID
    let mode: ResonanceMode
    let soundscapeID: Int
    let position: Int
    let source: RecommendationCandidateSource
    let score: RecommendationScore
    let modelVersion: String
}

struct RecommendationBatch: Equatable, Sendable {
    let request: ResonanceRequest
    let sessionID: UUID
    let modelVersion: String
    let candidateCount: Int
    let items: [MatchedSoundscape]

    func context(for soundscapeID: Int) -> RecommendationContext? {
        guard let position = items.firstIndex(where: { $0.soundscape.id == soundscapeID }) else { return nil }
        let item = items[position]
        return RecommendationContext(
            requestID: request.id,
            sessionID: sessionID,
            mode: request.mode,
            soundscapeID: soundscapeID,
            position: position,
            source: item.source,
            score: item.score,
            modelVersion: modelVersion
        )
    }
}

struct RecommendationImpression: Codable, Equatable, Sendable {
    let context: RecommendationContext
    let shownAt: Date
}

struct RecommendationFeedbackRecord: Codable, Equatable, Sendable {
    let context: RecommendationContext
    let feedback: ResonanceFeedback
    let recordedAt: Date
}

struct ResonancePersonalizationState: Codable, Equatable, Sendable {
    var profile: ResonanceProfile
    var impressions: [RecommendationImpression]
    var feedback: [RecommendationFeedbackRecord]

    static var empty: ResonancePersonalizationState {
        ResonancePersonalizationState(profile: .empty, impressions: [], feedback: [])
    }
}

protocol ResonanceIntentParsing: Sendable {
    func request(from input: ResonanceInput, now: Date) -> ResonanceRequest
}

protocol ResonanceStatePersisting: Sendable {
    func load() async throws -> ResonancePersonalizationState?
    func save(_ state: ResonancePersonalizationState) async throws
    func reset() async throws
}

protocol ResonanceMatching: Sendable {
    func recommendations(for request: ResonanceRequest, limit: Int) async throws -> RecommendationBatch
    func returningRecommendations(limit: Int) async throws -> RecommendationBatch
    func recordImpressions(_ impressions: [RecommendationImpression]) async throws
    func recordFeedback(
        _ feedback: ResonanceFeedback,
        for soundscape: Soundscape,
        context: RecommendationContext
    ) async throws
    func resetPersonalization() async throws
}

extension ResonanceMatching {
    func recommendations(for request: ResonanceRequest) async throws -> RecommendationBatch {
        try await recommendations(for: request, limit: 20)
    }

    func returningRecommendations() async throws -> RecommendationBatch {
        try await returningRecommendations(limit: 20)
    }
}

extension ResonanceRequest {
    var preferenceVector: ResonanceVector {
        let target = targetState ?? defaultTargetState
        let base = ResonanceVector(
            pleasantness: target.pleasantness,
            arousal: target.arousal,
            social: mode == .mirror ? 0.55 : 0.35,
            memory: mode == .recall ? 0.95 : 0.3,
            nature: mode == .escape ? 0.85 : 0.55,
            urban: mode == .escape ? 0.15 : 0.4,
            focus: mode == .focus ? 0.95 : 0.55,
            intimacy: mode == .recall || mode == .mirror ? 0.8 : 0.45
        )
        guard mode == .shift, let currentState else { return base }
        let current = ResonanceVector(
            pleasantness: currentState.pleasantness,
            arousal: currentState.arousal,
            social: base.social,
            memory: base.memory,
            nature: base.nature,
            urban: base.urban,
            focus: base.focus,
            intimacy: base.intimacy
        )
        return current.blended(toward: base, rate: 0.58)
    }

    private var defaultTargetState: AffectState {
        switch mode {
        case .mirror:
            currentState ?? AffectState(pleasantness: 0.55, arousal: 0.45)
        case .shift:
            AffectState(pleasantness: 0.78, arousal: 0.22)
        case .escape:
            AffectState(pleasantness: 0.72, arousal: 0.42)
        case .focus:
            AffectState(pleasantness: 0.66, arousal: 0.28)
        case .recall:
            AffectState(pleasantness: 0.62, arousal: 0.38)
        case .discover:
            AffectState(pleasantness: 0.6, arousal: 0.55)
        }
    }
}

private extension ResonanceFeedback {
    func rewards(for mode: ResonanceMode) -> (session: Double, longTerm: Double) {
        switch kind {
        case .started:
            (0.08, 0)
        case .advanced:
            listenedSeconds < 10 ? (-0.45, 0) : (min(0.35, Double(listenedSeconds) / 180), 0.06)
        case .completed:
            switch mode {
            case .focus, .mirror: (0.55, 0.16)
            case .shift: (0.45, 0.14)
            case .escape, .discover: (0.35, 0.12)
            case .recall: (0.28, 0.1)
            }
        case .saved:
            (0.82, 0.58)
        case .replayed:
            (0.78, 0.66)
        case .resonated:
            (1, 0.78)
        case .goalReached:
            (1, 0.72)
        case .skipped:
            switch reason {
            case .notNow: (-0.58, 0)
            case .tooIntense: (-0.9, -0.16)
            case .dislike: (-1, -0.55)
            case .wrongPlace: (-0.7, -0.28)
            case .uncomfortableMemory: (-1, -0.62)
            case nil: (-0.5, -0.08)
            }
        }
    }
}

extension Double {
    var clampedUnit: Double { min(1, max(0, self)) }
}
