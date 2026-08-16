import Foundation

struct LocalResonanceIntentParser: ResonanceIntentParsing {
    func request(from input: ResonanceInput, now: Date = Date()) -> ResonanceRequest {
        let normalized = input.text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let mode = mode(for: normalized)
        let currentState = currentState(for: normalized)
        return ResonanceRequest(
            mode: mode,
            queryText: input.text,
            currentState: currentState,
            targetState: targetState(for: mode),
            avoidances: avoidances(for: normalized),
            inputProvenance: input.provenance,
            confidence: confidence(for: normalized, mode: mode, currentState: currentState),
            allowsMemoryAnchors: mode == .recall,
            requestedAt: now
        )
    }

    private func mode(for text: String) -> ResonanceMode {
        if contains(text, any: ResonanceLexicon.recallIntent) {
            return .recall
        }
        if contains(text, any: ResonanceLexicon.focusIntent) {
            return .focus
        }
        if contains(text, any: ResonanceLexicon.shiftIntent) {
            return .shift
        }
        if contains(text, any: ResonanceLexicon.escapeIntent) {
            return .escape
        }
        if contains(text, any: ResonanceLexicon.mirrorIntent) {
            return .mirror
        }
        return .discover
    }

    private func currentState(for text: String) -> AffectState? {
        if contains(text, any: ResonanceLexicon.anxiousState) {
            return AffectState(pleasantness: 0.28, arousal: 0.88)
        }
        if contains(text, any: ResonanceLexicon.sadState) {
            return AffectState(pleasantness: 0.2, arousal: 0.34)
        }
        if contains(text, any: ResonanceLexicon.tiredState) {
            return AffectState(pleasantness: 0.38, arousal: 0.22)
        }
        if contains(text, any: ResonanceLexicon.energizedState) {
            return AffectState(pleasantness: 0.82, arousal: 0.86)
        }
        return nil
    }

    private func targetState(for mode: ResonanceMode) -> AffectState? {
        switch mode {
        case .shift: AffectState(pleasantness: 0.78, arousal: 0.2)
        case .focus: AffectState(pleasantness: 0.68, arousal: 0.28)
        case .escape: AffectState(pleasantness: 0.72, arousal: 0.42)
        case .recall: AffectState(pleasantness: 0.62, arousal: 0.38)
        case .mirror, .discover: nil
        }
    }

    private func avoidances(for text: String) -> Set<ResonanceAvoidance> {
        var values: Set<ResonanceAvoidance> = []
        if contains(text, any: ResonanceLexicon.speechAvoidance) {
            values.insert(.speech)
        }
        if contains(text, any: ResonanceLexicon.suddenNoiseAvoidance) {
            values.insert(.suddenNoise)
        }
        if contains(text, any: ResonanceLexicon.urbanAvoidance) {
            values.insert(.urban)
        }
        if contains(text, any: ResonanceLexicon.natureAvoidance) {
            values.insert(.nature)
        }
        return values
    }

    private func confidence(for text: String, mode: ResonanceMode, currentState: AffectState?) -> Double {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0.2 }
        var value = mode == .discover ? 0.48 : 0.7
        if currentState != nil { value += 0.14 }
        return min(0.92, value)
    }

    private func contains(_ text: String, any phrases: [String]) -> Bool {
        phrases.contains { text.localizedCaseInsensitiveContains($0) }
    }
}
