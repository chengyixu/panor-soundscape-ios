import Foundation

struct ResonanceMatchingConfiguration: Sendable {
    let creatorIntentWeight: Double
    let collectivePerceptionWeight: Double
    let userArousalWeight: Double
    let diversityWeight: Double
    let recentExposurePenalty: Double
    let maximumSuddenNoiseRisk: Double
    let modelVersion: String

    init(
        creatorIntentWeight: Double = 0.1,
        collectivePerceptionWeight: Double = 0.3,
        userArousalWeight: Double = 0.6,
        diversityWeight: Double = 0.34,
        recentExposurePenalty: Double = 0.22,
        maximumSuddenNoiseRisk: Double = 0.72,
        modelVersion: String = "resonance-r0-ios-v1"
    ) {
        self.creatorIntentWeight = creatorIntentWeight
        self.collectivePerceptionWeight = collectivePerceptionWeight
        self.userArousalWeight = userArousalWeight
        self.diversityWeight = diversityWeight
        self.recentExposurePenalty = recentExposurePenalty
        self.maximumSuddenNoiseRisk = maximumSuddenNoiseRisk
        self.modelVersion = modelVersion
    }
}

struct ResonanceMatcher: Sendable {
    private struct ScoredCandidate: Sendable {
        let soundscape: Soundscape
        let features: SoundscapeMatchingFeatures
        let source: RecommendationCandidateSource
        let score: RecommendationScore
    }

    private let featureProvider: any SoundscapeFeatureProviding
    let configuration: ResonanceMatchingConfiguration

    init(
        featureProvider: any SoundscapeFeatureProviding = MetadataSoundscapeFeatureProvider(),
        configuration: ResonanceMatchingConfiguration = ResonanceMatchingConfiguration()
    ) {
        self.featureProvider = featureProvider
        self.configuration = configuration
    }

    func rank(
        _ candidates: [Soundscape],
        request: ResonanceRequest,
        profile: ResonanceProfile,
        limit: Int
    ) -> [MatchedSoundscape] {
        guard limit > 0 else { return [] }
        let eligible = candidates.compactMap { soundscape -> ScoredCandidate? in
            guard soundscape.isPublic,
                  soundscape.audioURL != nil,
                  !profile.blockedSoundscapeIDs.contains(soundscape.id) else { return nil }
            let features = featureProvider.features(for: soundscape)
            guard passesAvoidances(features, request: request) else { return nil }
            return score(soundscape, features: features, request: request, profile: profile)
        }
        let ordered = rerank(eligible, request: request, limit: limit)
        return ordered.enumerated().map { index, candidate in
            MatchedSoundscape(
                soundscape: candidate.soundscape,
                role: role(at: index),
                source: candidate.source,
                score: candidate.score,
                featureVector: candidate.features.collectivePerception
            )
        }
    }

    private func score(
        _ soundscape: Soundscape,
        features: SoundscapeMatchingFeatures,
        request: ResonanceRequest,
        profile: ResonanceProfile
    ) -> ScoredCandidate {
        let target = request.preferenceVector
        let creatorSemantic = semanticSimilarity(request.queryText, features.creatorIntentText)
        let creatorVector = target.similarity(to: features.creatorIntent)
        let creatorIntent = weightedAverage([(creatorVector, 0.62), (creatorSemantic, 0.38)])
        let geographicFit = geographicFit(soundscape, request: request)
        let collectiveMode = modeFit(features.collectivePerception, features: features, request: request)
        let collectivePerception = weightedAverage([
            (collectiveMode, request.mode == .discover ? 0.48 : 0.63),
            (features.editorialQuality, 0.19),
            (features.novelty, request.mode == .discover ? 0.22 : 0.08),
            (geographicFit, request.mode == .escape ? 0.2 : 0.06),
            (features.loopStability, request.mode == .focus ? 0.18 : 0.04)
        ])
        let collectiveSemantic = semanticSimilarity(request.queryText, features.collectiveText)
        let explicitArousal = weightedAverage([
            (target.similarity(to: features.collectivePerception), 0.72),
            (collectiveSemantic, 0.28)
        ])
        let sessionArousal = profile.session?.similarity(to: features.collectivePerception) ?? 0
        let longTermArousal = profile.longTerm?.similarity(to: features.collectivePerception) ?? 0
        var personalSignals: [(Double, Double)] = [
            (explicitArousal, 0.58 + request.confidence * 0.12)
        ]
        if profile.session != nil { personalSignals.append((sessionArousal, 0.24)) }
        if profile.longTerm != nil { personalSignals.append((longTermArousal, 0.08)) }
        let userArousal = weightedAverage(personalSignals)
        let repetitionPenalty = profile.recentlyExposedSoundscapeIDs.contains(soundscape.id)
            ? configuration.recentExposurePenalty
            : 0
        let riskPenalty = riskPenalty(features, request: request)
        let total = (
            configuration.creatorIntentWeight * creatorIntent
            + configuration.collectivePerceptionWeight * collectivePerception
            + configuration.userArousalWeight * userArousal
            - repetitionPenalty
            - riskPenalty
        ).clampedUnit
        let score = RecommendationScore(
            creatorIntent: creatorIntent,
            collectivePerception: collectivePerception,
            explicitArousal: explicitArousal,
            sessionArousal: sessionArousal,
            longTermArousal: longTermArousal,
            userArousal: userArousal,
            geographicFit: geographicFit,
            novelty: features.novelty,
            repetitionPenalty: repetitionPenalty,
            riskPenalty: riskPenalty,
            total: total
        )
        return ScoredCandidate(
            soundscape: soundscape,
            features: features,
            source: dominantSource(score, request: request, profile: profile),
            score: score
        )
    }

    private func rerank(
        _ candidates: [ScoredCandidate],
        request: ResonanceRequest,
        limit: Int
    ) -> [ScoredCandidate] {
        var remaining = candidates.sorted(by: stableScoreOrder)
        var selected: [ScoredCandidate] = []
        while !remaining.isEmpty, selected.count < limit {
            let bestIndex = remaining.indices.max { lhs, rhs in
                rerankScore(remaining[lhs], selected: selected, request: request, position: selected.count)
                    < rerankScore(remaining[rhs], selected: selected, request: request, position: selected.count)
            }!
            selected.append(remaining.remove(at: bestIndex))
        }
        return selected
    }

    private func rerankScore(
        _ candidate: ScoredCandidate,
        selected: [ScoredCandidate],
        request: ResonanceRequest,
        position: Int
    ) -> Double {
        guard !selected.isEmpty else { return candidate.score.total }
        let maximumSimilarity = selected.map { similarity(candidate, $0) }.max() ?? 0
        let diversity = 1 - maximumSimilarity
        let noveltyBoost = position == 2
            ? candidate.features.novelty * (request.mode == .discover ? 0.3 : 0.18)
            : 0
        return candidate.score.total * (1 - configuration.diversityWeight)
            + diversity * configuration.diversityWeight
            + noveltyBoost
    }

    private func similarity(_ lhs: ScoredCandidate, _ rhs: ScoredCandidate) -> Double {
        var value = lhs.features.collectivePerception.similarity(to: rhs.features.collectivePerception) * 0.42
        if lhs.soundscape.authorDisplay == rhs.soundscape.authorDisplay { value += 0.34 }
        if normalized(lhs.soundscape.locationName) == normalized(rhs.soundscape.locationName) { value += 0.16 }
        if normalized(lhs.soundscape.category) == normalized(rhs.soundscape.category) { value += 0.08 }
        return value.clampedUnit
    }

    private func passesAvoidances(
        _ features: SoundscapeMatchingFeatures,
        request: ResonanceRequest
    ) -> Bool {
        if request.avoidances.contains(.suddenNoise),
           features.suddenNoiseRisk > configuration.maximumSuddenNoiseRisk { return false }
        if request.avoidances.contains(.highArousal), features.collectivePerception.arousal > 0.72 { return false }
        if request.avoidances.contains(.speech), features.collectivePerception.social > 0.72 { return false }
        if request.avoidances.contains(.urban), features.collectivePerception.urban > 0.72 { return false }
        if request.avoidances.contains(.nature), features.collectivePerception.nature > 0.72 { return false }
        return true
    }

    private func modeFit(
        _ vector: ResonanceVector,
        features: SoundscapeMatchingFeatures,
        request: ResonanceRequest
    ) -> Double {
        let targetFit = request.preferenceVector.similarity(to: vector)
        switch request.mode {
        case .mirror:
            return targetFit
        case .shift:
            guard let current = request.currentState,
                  let target = request.targetState else { return targetFit }
            let startDistance = affectDistance(current, target)
            let candidate = AffectState(pleasantness: vector.pleasantness, arousal: vector.arousal)
            let remainingDistance = affectDistance(candidate, target)
            let progress = startDistance == 0 ? targetFit : (1 - remainingDistance / startDistance).clampedUnit
            let abruptness = affectDistance(current, candidate)
            let abruptPenalty = max(0, abruptness - 0.55) * 0.45
            return (targetFit * 0.6 + progress * 0.4 - abruptPenalty).clampedUnit
        case .escape:
            return weightedAverage([(targetFit, 0.6), (features.novelty, 0.25), (1 - vector.urban, 0.15)])
        case .focus:
            let stability = weightedAverage([(vector.focus, 0.5), (features.loopStability, 0.3), (1 - vector.arousal, 0.2)])
            return weightedAverage([(targetFit, 0.55), (stability, 0.45)])
        case .recall:
            let memory = request.allowsMemoryAnchors ? vector.memory : 0.35
            return weightedAverage([(targetFit, 0.55), (memory, 0.3), (vector.intimacy, 0.15)])
        case .discover:
            return weightedAverage([(targetFit, 0.35), (features.novelty, 0.45), (features.editorialQuality, 0.2)])
        }
    }

    private func riskPenalty(
        _ features: SoundscapeMatchingFeatures,
        request: ResonanceRequest
    ) -> Double {
        let sensitivity = switch request.mode {
        case .focus, .shift: 0.16
        case .recall, .mirror: 0.1
        case .escape, .discover: 0.05
        }
        return max(0, features.suddenNoiseRisk - 0.45) * sensitivity
    }

    private func geographicFit(_ soundscape: Soundscape, request: ResonanceRequest) -> Double {
        guard let requestLocation = request.location,
              let latitude = soundscape.latitude,
              let longitude = soundscape.longitude else { return 0.5 }
        let distance = haversineKilometers(
            from: requestLocation,
            to: CoarseLocation(latitude: latitude, longitude: longitude)
        )
        let normalizedDistance = min(1, distance / 5_000)
        return switch request.mode {
        case .escape: normalizedDistance
        case .discover: 0.4 + normalizedDistance * 0.6
        case .mirror, .shift, .focus, .recall: 1 - normalizedDistance
        }
    }

    private func dominantSource(
        _ score: RecommendationScore,
        request: ResonanceRequest,
        profile: ResonanceProfile
    ) -> RecommendationCandidateSource {
        var values: [(RecommendationCandidateSource, Double)] = [
            (.intent, score.creatorIntent * configuration.creatorIntentWeight),
            (.collective, score.collectivePerception * configuration.collectivePerceptionWeight),
            (.session, score.sessionArousal * (profile.session == nil ? 0 : 0.24)),
            (.longTerm, score.longTermArousal * (profile.longTerm == nil ? 0 : 0.08)),
            (.geographic, score.geographicFit * (request.mode == .escape ? 0.22 : 0.04)),
            (.editorial, score.collectivePerception * 0.06),
            (.exploration, score.novelty * (request.mode == .discover ? 0.24 : 0.05))
        ]
        if request.mode == .recall, request.allowsMemoryAnchors {
            values.append((.memory, score.explicitArousal * 0.24))
        }
        return values.max { $0.1 < $1.1 }?.0 ?? .collective
    }

    private func semanticSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let left = semanticTerms(lhs)
        let right = semanticTerms(rhs)
        guard !left.isEmpty, !right.isEmpty else { return 0.5 }
        let overlap = left.intersection(right).count
        let union = left.union(right).count
        let tokenScore = union == 0 ? 0 : Double(overlap) / Double(union)
        let substringScore = left.contains { term in
            term.count >= 2 && rhs.localizedCaseInsensitiveContains(term)
        } ? 0.65 : 0
        return max(tokenScore, substringScore).clampedUnit
    }

    private func semanticTerms(_ text: String) -> Set<String> {
        let normalized = normalized(text)
        var terms = Set(normalized.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        for (index, group) in ResonanceLexicon.semanticConcepts.enumerated()
        where group.contains(where: normalized.localizedCaseInsensitiveContains) {
            terms.insert("concept-\(index)")
        }
        return terms
    }

    private func affectDistance(_ lhs: AffectState, _ rhs: AffectState) -> Double {
        hypot(lhs.pleasantness - rhs.pleasantness, lhs.arousal - rhs.arousal) / sqrt(2)
    }

    private func haversineKilometers(from: CoarseLocation, to: CoarseLocation) -> Double {
        let radius = 6_371.0
        let latitudeDelta = (to.latitude - from.latitude) * .pi / 180
        let longitudeDelta = (to.longitude - from.longitude) * .pi / 180
        let startLatitude = from.latitude * .pi / 180
        let endLatitude = to.latitude * .pi / 180
        let value = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return radius * 2 * atan2(sqrt(value), sqrt(1 - value))
    }

    private func weightedAverage(_ values: [(Double, Double)]) -> Double {
        let positive = values.filter { $0.1 > 0 }
        let denominator = positive.reduce(0) { $0 + $1.1 }
        guard denominator > 0 else { return 0.5 }
        return (positive.reduce(0) { $0 + $1.0 * $1.1 } / denominator).clampedUnit
    }

    private func stableScoreOrder(_ lhs: ScoredCandidate, _ rhs: ScoredCandidate) -> Bool {
        if lhs.score.total == rhs.score.total { return lhs.soundscape.id < rhs.soundscape.id }
        return lhs.score.total > rhs.score.total
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func role(at index: Int) -> RecommendationRole {
        switch index {
        case 0: .closest
        case 1: .alternate
        case 2: .surprise
        default: .stream
        }
    }
}
