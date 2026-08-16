import SwiftUI

struct ExploreView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    @State private var model: ExploreViewModel
    @State private var query = ""
    @State private var searchScope: ExploreSearchScope = .all
    @State private var selectedFacet: ExploreFacet?
    @State private var durationFilter: ExploreDurationFilter?
    @FocusState private var searchFocused: Bool
    @AppStorage("soundscape.explore.recent-searches") private var storedRecentSearches = "[]"

    let player: AudioPlayerController

    init(repository: any SoundscapeRepository, player: AudioPlayerController) {
        _model = State(initialValue: ExploreViewModel(repository: repository))
        self.player = player
    }

    var body: some View {
        let locale = localeManager.current

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    if !isSearching {
                        ScreenHeader(title: loc(.exploreTitle))
                    }
                    searchField
                    content
                }
                .padding(.horizontal, SoundscapeTheme.screenPadding)
                .padding(.top, isSearching ? 18 : 14)
                .padding(.bottom, 36)
                .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: isSearching)
            }
            .scrollDismissesKeyboard(.interactively)
            .soundscapeScreenBackground()
            .refreshable { await model.load(forceRefresh: true) }
            .task { if case .idle = model.state { await model.load() } }
            .toolbarBackground(SoundscapeTheme.paper, for: .navigationBar)
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SoundscapeTheme.secondaryInk)
            TextField(loc(.exploreSearchPlaceholder), text: $query)
                .focused($searchFocused)
                .accessibilityIdentifier("explore-search-field")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { saveRecentSearch(query) }
                .onChange(of: query) { _, value in
                    if let durationFilter, value != durationFilter.title {
                        self.durationFilter = nil
                    }
                }
            if isSearching {
                Button {
                    query = ""
                    durationFilter = nil
                    searchScope = .all
                    searchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SoundscapeTheme.tertiaryInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(loc(.exploreClearSearch))
            }
        }
        .padding(.horizontal, 17)
        .frame(minHeight: 54)
        .background(.clear, in: Capsule())
        .overlay { Capsule().stroke(SoundscapeTheme.ink.opacity(0.62), lineWidth: 1) }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle, .loading:
            SoundscapeLoadingState(title: loc(.exploreLoading))
        case .loaded(let items) where items.isEmpty:
            EmptyStateView(
                title: loc(.exploreEmptyTitle),
                detail: loc(.exploreEmpty),
                systemImage: "waveform.path"
            )
        case .loaded(let items):
            if isSearching {
                searchResults(for: items)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                discovery(for: items)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        case .failed(let error):
            ErrorStateView(error: error) { Task { await model.load(forceRefresh: true) } }
        }
    }

    private func discovery(for items: [Soundscape]) -> some View {
        let popularTerms = ExploreDiscovery.popularTerms(from: items)
        let recordings = ExploreDiscovery.ordered(items)

        return VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 18) {
                Text(loc(.exploreBy))
                    .font(.headline)
                    .foregroundStyle(SoundscapeTheme.ink)
                HStack(alignment: .top, spacing: 8) {
                    ForEach(ExploreFacet.allCases) { facet in
                        Button {
                            withAnimation(reduceMotion ? nil : .smooth(duration: 0.24)) {
                                selectedFacet = selectedFacet == facet ? nil : facet
                            }
                        } label: {
                            VStack(spacing: 9) {
                                ZStack {
                                    Circle()
                                        .fill(selectedFacet == facet ? SoundscapeTheme.ink : .clear)
                                    Circle()
                                        .stroke(SoundscapeTheme.ink.opacity(0.62), lineWidth: 1)
                                    Image(systemName: facet.systemImage)
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundStyle(
                                            selectedFacet == facet ? SoundscapeTheme.paperRaised : SoundscapeTheme.ink
                                        )
                                }
                                .frame(width: 50, height: 50)
                                Text(facet.title)
                                    .font(.caption)
                                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(loc(.exploreBy)) \(facet.title)")
                    }
                }

                if let selectedFacet {
                    facetValues(selectedFacet, items: items)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            if !popularTerms.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text(loc(.explorePopularSearches))
                        .font(.headline)
                        .foregroundStyle(SoundscapeTheme.ink)
                    ExploreTagFlow(spacing: 9) {
                        ForEach(popularTerms, id: \.self) { term in
                            SoundscapeTag(title: term) { runSearch(term) }
                        }
                    }
                }
            }

            if !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(loc(.exploreRecentSearches))
                            .font(.headline)
                            .foregroundStyle(SoundscapeTheme.ink)
                        Spacer()
                        Button(loc(.exploreClear)) { storedRecentSearches = "[]" }
                            .font(.subheadline)
                            .foregroundStyle(SoundscapeTheme.ink)
                            .buttonStyle(.plain)
                    }
                    ForEach(recentSearches, id: \.self) { term in
                        HStack(spacing: 13) {
                            Button { runSearch(term) } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                                    Text(term)
                                        .foregroundStyle(SoundscapeTheme.ink)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Button { removeRecentSearch(term) } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(loc(.exploreDeleteSearch)) \(term)")
                        }
                        .padding(.vertical, 7)
                    }
                }
            }

            recordingList(title: loc(.exploreLatestRecordings), items: recordings, sequence: recordings)
        }
    }

    private func facetValues(_ facet: ExploreFacet, items: [Soundscape]) -> some View {
        ExploreTagFlow(spacing: 9) {
            ForEach(ExploreDiscovery.facetValues(for: facet, items: items)) { value in
                SoundscapeTag(title: value.title, selected: durationFilter == value.durationFilter && value.durationFilter != nil) {
                    if let duration = value.durationFilter {
                        durationFilter = duration
                        query = duration.title
                        searchScope = .all
                        saveRecentSearch(duration.title)
                    } else if let query = value.query {
                        runSearch(query)
                    }
                }
            }
        }
    }

    private func searchResults(for items: [Soundscape]) -> some View {
        let results = ExploreDiscovery.search(
            items,
            query: durationFilter == nil ? query : "",
            scope: searchScope,
            durationFilter: durationFilter
        )

        return VStack(alignment: .leading, spacing: 28) {
            searchScopes
            if results.isEmpty {
                EmptyStateView(
                    title: loc(.exploreNoResultsTitle),
                    detail: loc(.exploreNoResultsDetail),
                    systemImage: "magnifyingglass"
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    SoundscapeSectionHeader(title: loc(.exploreTopResults), trailing: "\(results.count)")
                    ForEach(Array(results.prefix(3))) { soundscape in
                        TopSoundscapeResult(soundscape: soundscape) {
                            Task { await player.openPlayer(soundscape, sequence: results, source: .explore) }
                        }
                    }
                }
                recordingList(title: loc(.exploreRecordings), items: results, sequence: results)
            }
        }
    }

    private var searchScopes: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(ExploreSearchScope.allCases) { scope in
                    Button {
                        searchScope = scope
                    } label: {
                        VStack(spacing: 9) {
                            Text(scope.title)
                                .font(.subheadline.weight(searchScope == scope ? .semibold : .regular))
                                .foregroundStyle(searchScope == scope ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                            Rectangle()
                                .fill(searchScope == scope ? SoundscapeTheme.ink : .clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(SoundscapeTheme.line.opacity(0.7)).frame(height: 0.75)
        }
    }

    private func recordingList(title: String, items: [Soundscape], sequence: [Soundscape]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SoundscapeSectionHeader(title: title, trailing: "\(items.count)")
                .padding(.bottom, 8)
            ForEach(items) { soundscape in
                SoundscapeSearchRow(soundscape: soundscape) {
                    Task { await player.openPlayer(soundscape, sequence: sequence, source: .explore) }
                }
                if soundscape.id != items.last?.id {
                    Divider().overlay(SoundscapeTheme.line.opacity(0.65))
                }
            }
        }
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || durationFilter != nil
    }

    private var recentSearches: [String] {
        guard let data = storedRecentSearches.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return values
    }

    private func runSearch(_ term: String) {
        durationFilter = nil
        searchScope = .all
        query = term
        searchFocused = false
        saveRecentSearch(term)
    }

    private func saveRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let updated = [trimmed] + recentSearches.filter {
            $0.localizedCaseInsensitiveCompare(trimmed) != .orderedSame
        }
        if let data = try? JSONEncoder().encode(Array(updated.prefix(6))),
           let encoded = String(data: data, encoding: .utf8) {
            storedRecentSearches = encoded
        }
    }

    private func removeRecentSearch(_ term: String) {
        let updated = recentSearches.filter { $0 != term }
        if let data = try? JSONEncoder().encode(updated),
           let encoded = String(data: data, encoding: .utf8) {
            storedRecentSearches = encoded
        }
    }
}

private struct TopSoundscapeResult: View {
    @Environment(LocaleManager.self) private var localeManager
    let soundscape: Soundscape
    let play: () -> Void

    var body: some View {
        let locale = localeManager.current

        Button(action: play) {
            HStack(spacing: 16) {
                RemoteCover(url: soundscape.coverURL, category: soundscape.category, isAI: soundscape.coverIsAI)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 2).stroke(SoundscapeTheme.line, lineWidth: 0.75) }
                VStack(alignment: .leading, spacing: 6) {
                    Text(soundscape.displayTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SoundscapeTheme.ink)
                        .lineLimit(2)
                    Text(soundscape.authorDisplay)
                        .font(.subheadline)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                        .lineLimit(1)
                    Text("\(soundscape.locationDisplay) · \(soundscape.categoryDisplay)")
                        .font(.caption)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                        .lineLimit(2)
                    Text(soundscape.durationDisplay)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "play")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(SoundscapeTheme.ink)
                    .frame(width: 44, height: 44)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(loc(.explorePlayRecording)) \(soundscape.displayTitle), \(soundscape.locationDisplay)")
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}

private struct SoundscapeSearchRow: View {
    @Environment(LocaleManager.self) private var localeManager
    let soundscape: Soundscape
    let play: () -> Void

    var body: some View {
        let locale = localeManager.current

        Button(action: play) {
            HStack(spacing: 14) {
                RemoteCover(url: soundscape.coverURL, category: soundscape.category, isAI: soundscape.coverIsAI)
                    .frame(width: 66, height: 66)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 2).stroke(SoundscapeTheme.line, lineWidth: 0.75) }

                VStack(alignment: .leading, spacing: 4) {
                    Text(soundscape.displayTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SoundscapeTheme.ink)
                        .lineLimit(1)
                    Text("\(soundscape.authorDisplay) · \(soundscape.categoryDisplay)")
                        .font(.subheadline)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                        .lineLimit(1)
                    Text("\(soundscape.locationDisplay) · \(soundscape.durationDisplay)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "play")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(SoundscapeTheme.ink)
                    .frame(width: 40, height: 40)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(loc(.explorePlayRecording)) \(soundscape.displayTitle), \(soundscape.locationDisplay)")
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}

private struct ExploreTagFlow: Layout {
    var spacing: CGFloat = 8

    struct Cache {
        var frames: [CGRect] = []
        var size: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        cache = layout(proposal: proposal, subviews: subviews)
        return cache.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        if cache.frames.count != subviews.count {
            cache = layout(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews)
        }
        for (index, subview) in subviews.enumerated() {
            let frame = cache.frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> Cache {
        let availableWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var cursor = CGPoint.zero
        var lineHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            if availableWidth.isFinite {
                size.width = min(size.width, availableWidth)
            }
            if cursor.x > 0, cursor.x + size.width > availableWidth {
                cursor.x = 0
                cursor.y += lineHeight + spacing
                lineHeight = 0
            }
            frames.append(CGRect(origin: cursor, size: size))
            cursor.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            usedWidth = max(usedWidth, cursor.x - spacing)
        }

        return Cache(
            frames: frames,
            size: CGSize(width: availableWidth.isFinite ? availableWidth : usedWidth, height: cursor.y + lineHeight)
        )
    }
}
