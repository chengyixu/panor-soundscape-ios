import Foundation

struct MetadataSoundscapeFeatureProvider: SoundscapeFeatureProviding {
    func features(for soundscape: Soundscape) -> SoundscapeMatchingFeatures {
        let creatorText = soundscape.promptText
        let collectiveText = [
            soundscape.title,
            soundscape.description,
            soundscape.category,
            soundscape.locationName
        ].joined(separator: " ")
        let creatorIntent = vector(
            from: creatorText,
            social: soundscape.personalSocial,
            memoryPresent: soundscape.memoryPresent
        )
        let collectivePerception = vector(
            from: collectiveText,
            social: soundscape.personalSocial,
            memoryPresent: soundscape.memoryPresent
        )
        let engagement = quality(
            plays: soundscape.playCount,
            completions: soundscape.fullPlayCount,
            saves: soundscape.saveCount
        )
        let novelty = 1 - min(1, log1p(Double(max(0, soundscape.playCount))) / log(1_001))
        let suddenNoiseRisk = lexicalScore(
            collectiveText,
            phrases: ResonanceLexicon.suddenNoiseContent
        )
        let instability = lexicalScore(
            collectiveText,
            phrases: ResonanceLexicon.unstableContent
        )
        return SoundscapeMatchingFeatures(
            creatorIntent: creatorIntent,
            collectivePerception: collectivePerception,
            creatorIntentText: creatorText,
            collectiveText: collectiveText,
            editorialQuality: engagement,
            novelty: novelty,
            suddenNoiseRisk: suddenNoiseRisk,
            loopStability: 1 - instability * 0.75
        )
    }

    private func vector(from text: String, social: Double, memoryPresent: Double) -> ResonanceVector {
        let calm = lexicalScore(
            text,
            phrases: ResonanceLexicon.calmContent
        )
        let energy = lexicalScore(
            text,
            phrases: ResonanceLexicon.energyContent
        )
        let nature = lexicalScore(
            text,
            phrases: ResonanceLexicon.natureContent
        )
        let urban = lexicalScore(
            text,
            phrases: ResonanceLexicon.urbanContent
        )
        let memory = max(
            1 - memoryPresent.clampedUnit,
            lexicalScore(text, phrases: ResonanceLexicon.memoryContent)
        )
        let focus = max(
            calm * 0.75,
            lexicalScore(text, phrases: ResonanceLexicon.focusContent)
        )
        let pleasantness = (0.5 + calm * 0.35 - energy * 0.16).clampedUnit
        let arousal = (0.45 + energy * 0.48 - calm * 0.3).clampedUnit
        return ResonanceVector(
            pleasantness: pleasantness,
            arousal: arousal,
            social: social,
            memory: memory,
            nature: max(nature, urban == 0 ? 0.5 : 0.1),
            urban: max(urban, nature == 0 ? 0.5 : 0.1),
            focus: focus,
            intimacy: max(0.15, 1 - social * 0.72)
        )
    }

    private func quality(plays: Int, completions: Int, saves: Int) -> Double {
        let playCount = Double(max(0, plays))
        let weightedPositive = Double(max(0, completions)) + Double(max(0, saves)) * 1.5
        let posterior = (weightedPositive + 2.5) / (playCount + 6)
        let confidence = min(1, log1p(playCount) / log(101))
        return (0.58 * (1 - confidence) + posterior.clampedUnit * confidence).clampedUnit
    }

    private func lexicalScore(_ text: String, phrases: [String]) -> Double {
        guard !text.isEmpty else { return 0 }
        let matches = phrases.reduce(into: 0) { count, phrase in
            if text.localizedCaseInsensitiveContains(phrase) { count += 1 }
        }
        return min(1, Double(matches) / 2)
    }
}
