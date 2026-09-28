import SwiftUI

struct ThemesView: View {
    let repository: any SoundscapeRepository
    let player: AudioPlayerController
    let contribute: (ListeningTheme) -> Void
    @State private var state: LoadState<[ListeningTheme]> = .idle
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(title: loc(.themeTitle))
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField(loc(.themeChoose), text: $query)
                            .textInputAutocapitalization(.never)
                            .accessibilityIdentifier("themes-search")
                    }
                    .padding(14).background(SoundscapeTheme.paperRaised, in: Capsule())
                    switch state {
                    case .idle, .loading: ProgressView().frame(maxWidth: .infinity)
                    case .failed(let error): ErrorStateView(error: error) { Task { await load() } }
                    case .loaded(let themes):
                        let matches = themes.filter { query.isEmpty || $0.title.localizedStandardContains(query) || $0.description.localizedStandardContains(query) }
                        if matches.isEmpty { Text(loc(.themeEmpty)).foregroundStyle(SoundscapeTheme.secondaryInk) }
                        ForEach(matches) { theme in
                            NavigationLink {
                                ThemeDetailView(theme: theme, repository: repository, player: player, contribute: contribute)
                            } label: { ThemeRow(theme: theme) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("theme-\(theme.id)")
                            Divider()
                        }
                    }
                }
                .padding(SoundscapeTheme.screenPadding)
            }
            .soundscapeScreenBackground()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        state = .loading
        do { state = .loaded(try await repository.themes()) }
        catch { state = .failed((error as? AppError) ?? .transport(String(describing: type(of: error)))) }
    }
}

struct ThemeRow: View {
    let theme: ListeningTheme
    var body: some View {
        HStack(spacing: 14) {
            ThemeArtwork(themeID: theme.id, size: 56)
            VStack(alignment: .leading, spacing: 5) {
                Text(theme.title).font(.headline).foregroundStyle(SoundscapeTheme.ink)
                Text(loc(theme.kind == .event ? .themeEvent : .themeTopic))
                    .font(.caption).foregroundStyle(SoundscapeTheme.secondaryInk)
                if let count = theme.recordingCount {
                    Text("\(count) \(loc(.themeRecordings))")
                        .font(.caption.monospacedDigit()).foregroundStyle(SoundscapeTheme.secondaryInk)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(SoundscapeTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct ThemeDetailView: View {
    let theme: ListeningTheme
    let repository: any SoundscapeRepository
    let player: AudioPlayerController
    let contribute: (ListeningTheme) -> Void
    @State private var state: LoadState<[Soundscape]> = .idle
    @State private var playbackError: AppError?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ThemeRow(theme: theme)
                if let starts = theme.startsOn { Text([starts, theme.endsOn].compactMap { $0 }.joined(separator: " – ")).font(.subheadline) }
                if !theme.description.isEmpty { Text(theme.description).foregroundStyle(SoundscapeTheme.secondaryInk) }
                Button(loc(.themeContribute)) { contribute(theme) }
                    .buttonStyle(PrimaryActionStyle())
                    .accessibilityIdentifier("theme-contribute")
                switch state {
                case .idle, .loading: ProgressView()
                case .failed(let error): ErrorStateView(error: error) { Task { await load() } }
                case .loaded(let items):
                    if !items.isEmpty {
                        Button(loc(.themeListen)) { listen() }.buttonStyle(SecondaryActionStyle())
                    }
                    Text("\(items.count) \(loc(.themeRecordings))").font(.caption).foregroundStyle(SoundscapeTheme.secondaryInk)
                    ForEach(items) { item in
                        Button { listen(item) } label: {
                            HStack(spacing: 12) {
                                RemoteCover(url: item.coverURL, category: item.category, isAI: item.coverIsAI, avatarSeed: item.id)
                                    .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.displayTitle).font(.headline).lineLimit(2)
                                    Text(item.authorDisplay).font(.caption).foregroundStyle(SoundscapeTheme.secondaryInk)
                                }
                                Spacer()
                                Image(systemName: "play").frame(width: 44, height: 44)
                            }
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                if let playbackError { Text(playbackError.userMessage).font(.footnote).foregroundStyle(SoundscapeTheme.secondaryInk) }
            }
            .padding(SoundscapeTheme.screenPadding)
        }
        .soundscapeScreenBackground()
        .navigationTitle(theme.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        state = .loading
        do { state = .loaded(try await repository.recordings(themeID: theme.id)) }
        catch { state = .failed((error as? AppError) ?? .transport(String(describing: type(of: error)))) }
    }
    private func listen(_ item: Soundscape? = nil) {
        Task {
            do { try await player.openThemePlayer(theme, startingAt: item?.id); playbackError = nil }
            catch { playbackError = (error as? AppError) ?? .transport(String(describing: type(of: error))) }
        }
    }
}

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: any SoundscapeRepository
    @Binding var selection: ListeningTheme?
    @State private var state: LoadState<[ListeningTheme]> = .idle

    var body: some View {
        NavigationStack {
            List {
                Button(loc(.themeNone)) { selection = nil; dismiss() }
                switch state {
                case .idle, .loading: ProgressView()
                case .failed(let error): ErrorStateView(error: error) { Task { await load() } }
                case .loaded(let themes):
                    ForEach(themes) { theme in
                        Button { selection = theme; dismiss() } label: { ThemeRow(theme: theme) }
                    }
                }
            }
            .navigationTitle(loc(.themeChoose))
            .toolbar { Button(loc(.generalDone)) { dismiss() } }
            .task { await load() }
        }
    }
    private func load() async {
        state = .loading
        do { state = .loaded(try await repository.themes()) }
        catch { state = .failed((error as? AppError) ?? .transport(String(describing: type(of: error)))) }
    }
}
