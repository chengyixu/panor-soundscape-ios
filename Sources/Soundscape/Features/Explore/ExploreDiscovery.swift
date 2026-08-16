import Foundation

enum ExploreFacet: String, CaseIterable, Identifiable {
    case category
    case location
    case author
    case recording
    case duration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .category: loc(.exploreFacetCategory)
        case .location: loc(.exploreSearchLocation)
        case .author: loc(.exploreSearchAuthor)
        case .recording: loc(.exploreFacetRecording)
        case .duration: loc(.exploreFacetDuration)
        }
    }

    var systemImage: String {
        switch self {
        case .category: "waveform"
        case .location: "mappin"
        case .author: "person"
        case .recording: "record.circle"
        case .duration: "clock"
        }
    }
}

enum ExploreSearchScope: String, CaseIterable, Identifiable {
    case all
    case title
    case location
    case author
    case category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: loc(.exploreSearchAll)
        case .title: loc(.exploreFacetRecording)
        case .location: loc(.exploreSearchLocation)
        case .author: loc(.exploreSearchAuthor)
        case .category: loc(.exploreFacetCategory)
        }
    }
}

enum ExploreDurationFilter: String, CaseIterable, Identifiable {
    case underOneMinute
    case oneToFiveMinutes
    case overFiveMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .underOneMinute: loc(.exploreDurationUnder1min)
        case .oneToFiveMinutes: .loc(.exploreDuration1to5min)
        case .overFiveMinutes: .loc(.exploreDurationOver5min)
        }
    }

    func contains(_ seconds: Int) -> Bool {
        switch self {
        case .underOneMinute: seconds < 60
        case .oneToFiveMinutes: (60...300).contains(seconds)
        case .overFiveMinutes: seconds > 300
        }
    }
}

struct ExploreFacetValue: Identifiable, Equatable {
    let title: String
    let query: String?
    let durationFilter: ExploreDurationFilter?

    var id: String {
        [title, query ?? "", durationFilter?.rawValue ?? ""].joined(separator: "|")
    }
}

enum ExploreDiscovery {
    static func ordered(_ items: [Soundscape]) -> [Soundscape] {
        items.sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.id > $1.id
        }
    }

    static func search(
        _ items: [Soundscape],
        query: String,
        scope: ExploreSearchScope,
        durationFilter: ExploreDurationFilter?
    ) -> [Soundscape] {
        let needle = normalized(query)
        return items
            .filter { item in
                guard durationFilter?.contains(item.durationSeconds) ?? true else { return false }
                guard !needle.isEmpty else { return true }
                return searchableValues(for: item, scope: scope).contains {
                    normalized($0).contains(needle)
                }
            }
            .sorted {
                let left = relevance(of: $0, needle: needle, scope: scope)
                let right = relevance(of: $1, needle: needle, scope: scope)
                if left != right { return left > right }
                if engagement(of: $0) != engagement(of: $1) {
                    return engagement(of: $0) > engagement(of: $1)
                }
                return $0.createdAt > $1.createdAt
            }
    }

    static func popularTerms(from items: [Soundscape], limit: Int = 10) -> [String] {
        var terms: [String: (title: String, score: Int)] = [:]

        for item in items {
            let score = max(1, engagement(of: item))
            add(item.categoryDisplay, score: score * 2, to: &terms)
            for location in locationSegments(item.locationName) {
                add(location, score: score, to: &terms)
            }
            if item.displayTitle.count <= 24 {
                add(item.displayTitle, score: score, to: &terms)
            }
            if !item.authorDisplay.allSatisfy(\.isNumber) {
                add(item.authorDisplay, score: score, to: &terms)
            }
        }

        return terms.values
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                if $0.title.count != $1.title.count { return $0.title.count < $1.title.count }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            .prefix(max(0, limit))
            .map(\.title)
    }

    static func facetValues(for facet: ExploreFacet, items: [Soundscape], limit: Int = 10) -> [ExploreFacetValue] {
        switch facet {
        case .category:
            return rankedCategoryValues(items, limit: limit)
        case .location:
            return rankedValues(
                items.flatMap { item in locationSegments(item.locationName).map { ($0, engagement(of: item)) } },
                limit: limit
            )
        case .author:
            return rankedValues(items.map { ($0.authorDisplay, engagement(of: $0)) }, limit: limit)
        case .recording:
            return rankedValues(items.map { ($0.displayTitle, engagement(of: $0)) }, limit: limit)
        case .duration:
            return ExploreDurationFilter.allCases.compactMap { filter in
                guard items.contains(where: { filter.contains($0.durationSeconds) }) else { return nil }
                return ExploreFacetValue(title: filter.title, query: nil, durationFilter: filter)
            }
        }
    }

    static func locationSegments(_ location: String) -> [String] {
        location
            .components(separatedBy: CharacterSet(charactersIn: "·,，"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func rankedValues(_ values: [(String, Int)], limit: Int) -> [ExploreFacetValue] {
        var ranked: [String: (title: String, score: Int)] = [:]
        for (title, score) in values {
            add(title, score: max(1, score), to: &ranked)
        }
        return ranked.values
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            .prefix(max(0, limit))
            .map { ExploreFacetValue(title: $0.title, query: $0.title, durationFilter: nil) }
    }

    private static func rankedCategoryValues(_ items: [Soundscape], limit: Int) -> [ExploreFacetValue] {
        var scores: [String: Int] = [:]
        for item in items {
            scores[item.category, default: 0] += max(1, engagement(of: item))
        }
        return scores
            .sorted {
                if $0.value != $1.value { return $0.value > $1.value }
                return $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
            }
            .prefix(max(0, limit))
            .map { rawValue, _ in
                ExploreFacetValue(
                    title: SoundscapeCategory.localizedTitle(for: rawValue),
                    query: rawValue,
                    durationFilter: nil
                )
            }
    }

    private static func add(
        _ title: String,
        score: Int,
        to terms: inout [String: (title: String, score: Int)]
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = normalized(trimmed)
        guard !key.isEmpty else { return }
        if let existing = terms[key] {
            terms[key] = (existing.title, existing.score + score)
        } else {
            terms[key] = (trimmed, score)
        }
    }

    private static func relevance(of item: Soundscape, needle: String, scope: ExploreSearchScope) -> Int {
        guard !needle.isEmpty else { return engagement(of: item) }
        return searchableValues(for: item, scope: scope).reduce(0) { best, value in
            let candidate = normalized(value)
            let score: Int
            if candidate == needle {
                score = 1_000
            } else if candidate.hasPrefix(needle) {
                score = 700
            } else if candidate.contains(needle) {
                score = 400
            } else {
                score = 0
            }
            return max(best, score)
        } + engagement(of: item)
    }

    private static func searchableValues(for item: Soundscape, scope: ExploreSearchScope) -> [String] {
        switch scope {
        case .all:
            [
                item.displayTitle,
                item.locationDisplay,
                item.authorDisplay,
                item.category,
                item.categoryDisplay,
                item.description,
                item.promptText
            ]
        case .title: [item.displayTitle]
        case .location: [item.locationDisplay]
        case .author: [item.authorDisplay]
        case .category: [item.category, item.categoryDisplay]
        }
    }

    private static func engagement(of item: Soundscape) -> Int {
        1 + item.playCount + item.fullPlayCount * 2 + item.saveCount * 4
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
