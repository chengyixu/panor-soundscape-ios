import SwiftUI

enum LibraryFilter: String, CaseIterable, Identifiable {
    case recordings = "Recordings" // rawValue kept as key
    case publicItems = "Public" // rawValue kept as key
    case privateItems = "Private" // rawValue kept as key

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .recordings: loc(.libraryFilterRecordings)
        case .publicItems: loc(.libraryFilterPublic)
        case .privateItems: loc(.libraryFilterPrivate)
        }
    }
}

struct LibraryView: View {
    @Environment(LocaleManager.self) private var localeManager
    @State private var model: LibraryViewModel
    let repository: any SoundscapeRepository
    let recorder: any RecordingService
    let session: IdentitySession
    let player: AudioPlayerController
    let matching: any ResonanceMatching
    let intentParser: any ResonanceIntentParsing
    @State private var showsIdentity = false
    @State private var showsSettings = false
    @State private var pendingDelete: Soundscape?
    @State private var filter: LibraryFilter = .recordings

    init(
        repository: any SoundscapeRepository,
        recorder: any RecordingService,
        session: IdentitySession,
        player: AudioPlayerController,
        matching: any ResonanceMatching,
        intentParser: any ResonanceIntentParsing
    ) {
        _model = State(initialValue: LibraryViewModel(repository: repository))
        self.repository = repository
        self.recorder = recorder
        self.session = session
        self.player = player
        self.matching = matching
        self.intentParser = intentParser
    }

    var body: some View {
        let locale = localeManager.current

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    profileHeader
                    if session.user == nil { signedOut }
                    else {
                        filterTabs
                        content
                    }
                }
                .padding(.horizontal, SoundscapeTheme.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .soundscapeScreenBackground()
            .refreshable { if session.user != nil { await model.load() } }
            .task(id: session.user?.id) {
                if session.user != nil { await model.load() }
            }
            .sheet(isPresented: $showsIdentity) { IdentitySheet(session: session) }
            .sheet(isPresented: $showsSettings) {
                SettingsView(
                    recorder: recorder,
                    player: player,
                    matching: matching,
                    intentParser: intentParser
                )
            }
            .confirmationDialog(loc(.libraryDeleteConfirm), isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ), titleVisibility: .visible) {
                Button(loc(.libraryDelete), role: .destructive) {
                    if let pendingDelete { Task { await model.delete(pendingDelete) } }
                    pendingDelete = nil
                }
                Button(loc(.generalCancel), role: .cancel) { pendingDelete = nil }
            }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private var profileHeader: some View {
        HStack(spacing: 15) {
            profileIdentityControl

            VStack(alignment: .leading, spacing: 4) {
                Text(session.user?.username ?? loc(.libraryYourSoundArchive))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SoundscapeTheme.ink)
                Text(session.user == nil ? loc(.libraryPrivateUntilSignIn) : loc(.librarySoundRecorder))
                    .font(.subheadline)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            Spacer()
            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(SoundscapeTheme.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(loc(.settingsTitle))
            .accessibilityIdentifier("settings-button")
        }
    }

    @ViewBuilder private var profileIdentityControl: some View {
        profileAvatar
            .onTapGesture {
                if session.user != nil {
                    showsSettings = true
                }
            }
    }


    private var profileAvatar: some View {
        Circle()
            .fill(SoundscapeTheme.paperDeep)
            .frame(width: 68, height: 68)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
    }

    private var filterTabs: some View {
        HStack(spacing: 28) {
            ForEach(LibraryFilter.allCases) { option in
                Button {
                    filter = option
                } label: {
                    VStack(spacing: 9) {
                        Text(option.displayName)
                            .font(.subheadline.weight(filter == option ? .semibold : .regular))
                            .foregroundStyle(filter == option ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                        Rectangle()
                            .fill(filter == option ? SoundscapeTheme.ink : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(SoundscapeTheme.line.opacity(0.7)).frame(height: 0.75)
        }
    }

    private var signedOut: some View {
        VStack(alignment: .leading, spacing: 16) {
            EmptyStateView(title: loc(.librarySignedOutTitle), detail: loc(.librarySignedOutDetail), systemImage: "person.crop.circle.badge.questionmark")
            Button(loc(.librarySignInOrRegister)) { showsIdentity = true }.buttonStyle(PrimaryActionStyle())
        }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle, .loading:
            SoundscapeLoadingState(title: loc(.libraryReadingRecordings))
        case .failed(let error):
            ErrorStateView(error: error) { Task { await model.load() } }
        case .loaded(let items) where filtered(items).isEmpty:
            EmptyStateView(title: loc(.libraryNoRecordingsTitle), detail: loc(.libraryNoRecordingsDetail), systemImage: "waveform.badge.plus")
        case .loaded(let items):
            let visibleItems = filtered(items)
            VStack(alignment: .leading, spacing: 24) {
                if let featured = visibleItems.first {
                    LibraryHero(item: featured) {
                        Task { await player.openPlayer(featured, sequence: visibleItems, source: .library) }
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    SoundscapeSectionHeader(title: loc(.libraryMyRecordingsHeader), trailing: "\(visibleItems.count)")
                        .padding(.bottom, 8)
                    ForEach(visibleItems) { item in
                        LibraryRow(
                            item: item,
                            play: { Task { await player.openPlayer(item, sequence: visibleItems, source: .library) } },
                            visibility: { Task { await model.toggleVisibility(item) } },
                            delete: { pendingDelete = item }
                        )
                        if item.id != visibleItems.last?.id {
                            Divider().overlay(SoundscapeTheme.line.opacity(0.65))
                        }
                    }
                }
            }
            if let error = model.mutationError {
                Label(error.userMessage, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(SoundscapeTheme.ink)
            }
        }
    }

    private func filtered(_ items: [Soundscape]) -> [Soundscape] {
        switch filter {
        case .recordings: items
        case .publicItems: items.filter(\.isPublic)
        case .privateItems: items.filter { !$0.isPublic }
        }
    }

private struct LibraryHero: View {
    @Environment(LocaleManager.self) private var localeManager
    let item: Soundscape
    let play: () -> Void

    var body: some View {
        let locale = localeManager.current

        Button(action: play) {
            RemoteCover(url: item.coverURL, category: item.category, isAI: item.coverIsAI)
                .frame(height: 292)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(.black.opacity(0.58)).frame(height: 128)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.displayTitle)
                            .font(.system(size: 27, weight: .semibold))
                            .lineLimit(2)
                        Text(item.locationDisplay)
                            .font(.headline.weight(.regular))
                        Label(item.categoryDisplay, systemImage: "location")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .frame(width: 58, height: 58)
                        .background(.white, in: Circle())
                        .padding(18)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(loc(.libraryPlayFeaturedRecording)) \(item.displayTitle)")
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}

private struct LibraryRow: View {
    @Environment(LocaleManager.self) private var localeManager
    let item: Soundscape
    let play: () -> Void
    let visibility: () -> Void
    let delete: () -> Void

    var body: some View {
        let locale = localeManager.current

        HStack(spacing: 14) {
            RemoteCover(url: item.coverURL, category: item.category, isAI: item.coverIsAI)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle).font(.headline).lineLimit(1)
                Text(item.locationDisplay).font(.subheadline).foregroundStyle(SoundscapeTheme.secondaryInk).lineLimit(1)
                Text("\(durationText)  ·  \(item.isPublic ? loc(.libraryPublicLabel) : loc(.libraryPrivateLabel))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: play) {
                Image(systemName: "play")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Menu {
                Button(item.isPublic ? loc(.libraryMakePrivate) : loc(.libraryMakePublic), action: visibility)
                Button(loc(.libraryDelete), role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis.vertical").frame(width: 32, height: 44)
            }
        }
        .foregroundStyle(SoundscapeTheme.ink)
        .padding(.vertical, 12)
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private var durationText: String {
        let seconds = max(0, item.durationSeconds)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
}
