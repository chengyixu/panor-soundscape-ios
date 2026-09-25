import SwiftUI
import PhotosUI

enum LibraryFilter: String, CaseIterable, Identifiable {
    case recordings = "Recordings" // rawValue kept as key
    case publicItems = "Public" // rawValue kept as key
    case privateItems = "Private" // rawValue kept as key
    case favorites = "Favorites" // rawValue kept as key
    case review = "Review"

    static func visibleFilters(canModerate: Bool) -> [LibraryFilter] {
        canModerate ? allCases : allCases.filter { $0 != .review }
    }

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .recordings: loc(.libraryFilterRecordings)
        case .publicItems: loc(.libraryFilterPublic)
        case .privateItems: loc(.libraryFilterPrivate)
        case .favorites: loc(.librarySaved)
        case .review: loc(.moderationTab)
        }
    }
}

struct LibraryFilterLayout: Layout {
    static let spacing: CGFloat = 8
    static let minimumItemWidth: CGFloat = 76
    var minimumWidth: CGFloat = minimumItemWidth

    static func itemWidth(availableWidth: CGFloat, itemCount: Int = LibraryFilter.allCases.count) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        return max(minimumItemWidth, (availableWidth - spacing * CGFloat(itemCount - 1)) / CGFloat(itemCount))
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = max(proposedWidth(proposal: proposal, subviews: subviews),
                        CGFloat(subviews.count) * minimumWidth + CGFloat(max(0, subviews.count - 1)) * Self.spacing)
        let itemWidth = max(minimumWidth, Self.itemWidth(availableWidth: width, itemCount: subviews.count))
        let height = subviews.map {
            $0.sizeThatFits(ProposedViewSize(width: itemWidth, height: proposal.height)).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let itemWidth = max(minimumWidth, Self.itemWidth(availableWidth: bounds.width, itemCount: subviews.count))
        for (index, subview) in subviews.enumerated() {
            let x = bounds.minX + CGFloat(index) * (itemWidth + Self.spacing)
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: itemWidth, height: bounds.height)
            )
        }
    }

    private func proposedWidth(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        if let width = proposal.width { return width }
        let intrinsicWidth = subviews.reduce(CGFloat.zero) { partialResult, subview in
            partialResult + subview.sizeThatFits(.unspecified).width
        }
        return intrinsicWidth + Self.spacing * CGFloat(max(0, subviews.count - 1))
    }
}

struct LibraryView: View {
    @Environment(LocaleManager.self) private var localeManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var model: LibraryViewModel
    let repository: any SoundscapeRepository
    let moderation: any ModerationRepository
    let recorder: any RecordingService
    let session: IdentitySession
    let player: AudioPlayerController
    let matching: any ResonanceMatching
    let intentParser: any ResonanceIntentParsing
    let isActive: Bool
    @State private var showsIdentity = false
    @State private var showsSettings = false
    @State private var canModerate = false
    @State private var pendingDelete: Soundscape?
    @State private var filter: LibraryFilter = .recordings
    @State private var favoriteActionError: AppError?
    @State private var selectedAvatarPhoto: PhotosPickerItem?
    @State private var isShowingAvatarPicker = false
    @State private var avatarActionError: AppError?
    @State private var isSavingAvatar = false

    init(
        repository: any SoundscapeRepository,
        moderation: any ModerationRepository,
        recorder: any RecordingService,
        session: IdentitySession,
        player: AudioPlayerController,
        matching: any ResonanceMatching,
        intentParser: any ResonanceIntentParsing,
        isActive: Bool
    ) {
        _model = State(initialValue: LibraryViewModel(repository: repository))
        self.repository = repository
        self.moderation = moderation
        self.recorder = recorder
        self.session = session
        self.player = player
        self.matching = matching
        self.intentParser = intentParser
        self.isActive = isActive
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
            .task(id: "\(session.user?.id ?? "signed-out"):\(isActive)") {
                if session.user != nil, isActive {
                    canModerate = false
                    if filter == .review { filter = .recordings }
                    await model.load()
                    do {
                        canModerate = try await moderation.hasModeratorAccess()
                    } catch {
                        // Role lookup failures must not masquerade as avatar errors.
                        canModerate = false
                    }
                } else if session.user == nil { canModerate = false; filter = .recordings }
            }
            .sheet(isPresented: $showsIdentity) { IdentitySheet(session: session) }
            .onChange(of: selectedAvatarPhoto) { _, selection in
                guard let selection else { return }
                Task { await updateAvatar(from: selection) }
            }
            .alert(loc(.libraryAvatarUploadFailed), isPresented: Binding(
                get: { avatarActionError != nil || session.avatarError != nil },
                set: { if !$0 { avatarActionError = nil; session.dismissAvatarError() } }
            )) {
                Button(loc(.generalOK)) { avatarActionError = nil; session.dismissAvatarError() }
            } message: {
                Text((avatarActionError ?? session.avatarError)?.userMessage ?? loc(.errorTryAgain))
            }
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
            .alert(loc(.librarySaved), isPresented: Binding(
                get: { favoriteActionError != nil },
                set: { if !$0 { favoriteActionError = nil } }
            )) {
                Button(loc(.generalOK)) { favoriteActionError = nil }
            } message: {
                Text(favoriteActionError?.userMessage ?? loc(.errorTryAgain))
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
        if session.user != nil {
            Button { isShowingAvatarPicker = true } label: { profileAvatar }
            .buttonStyle(.plain)
            .photosPicker(isPresented: $isShowingAvatarPicker, selection: $selectedAvatarPhoto, matching: .images)
            .disabled(isSavingAvatar)
            .accessibilityLabel(loc(.libraryChangeAvatar))
            .accessibilityIdentifier("profile-avatar-picker")
        } else {
            Button { showsIdentity = true } label: { profileAvatar }
                .buttonStyle(.plain)
                .accessibilityLabel(loc(.librarySignInOrRegister))
                .accessibilityIdentifier("profile-avatar-sign-in")
        }
    }

    private var profileAvatar: some View {
        ZStack {
            SoundscapeAvatar(
                seed: session.user?.id ?? "guest",
                size: 68,
                photo: {
                    guard case .photo(let data) = session.avatar else { return nil }
                    return data
                }()
            )
            if isSavingAvatar { ProgressView().tint(.white) }
        }
        .accessibilityHidden(true)
    }

    private func updateAvatar(from selection: PhotosPickerItem) async {
        guard let userID = session.user?.id else { return }
        isSavingAvatar = true
        defer { isSavingAvatar = false; selectedAvatarPhoto = nil }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw AppError.invalidRequest(loc(.errorInvalidImage))
            }
            guard session.user?.id == userID else { return }
            let photo = try ProfileAvatarImageProcessor.normalizedJPEG(from: data)
            try await session.setAvatarPhoto(photo, for: userID)
        } catch let error as AppError {
            avatarActionError = error
        } catch {
            avatarActionError = .invalidRequest(loc(.errorCannotProcessImage))
        }
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LibraryFilterLayout(minimumWidth: dynamicTypeSize.isAccessibilitySize ? 150 : 76) {
                ForEach(LibraryFilter.visibleFilters(canModerate: canModerate)) { option in
                    Button { filter = option } label: {
                        VStack(spacing: 9) {
                            Text(option.displayName)
                                .font(.subheadline.weight(filter == option ? .semibold : .regular))
                                .lineLimit(1)
                                .foregroundStyle(filter == option ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                            Rectangle()
                                .fill(filter == option ? SoundscapeTheme.ink : .clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("library-filter-\(option.rawValue)")
                }
            }
            .frame(minWidth: dynamicTypeSize.isAccessibilitySize
                   ? CGFloat(canModerate ? 5 : 4) * 150 + CGFloat(canModerate ? 4 : 3) * LibraryFilterLayout.spacing
                   : canModerate ? 412 : 328)
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
        switch filter {
        case .favorites: favoriteContent
        case .review:
            if canModerate { ModeratorReviewView(repository: moderation) }
        default: recordingContent
        }
    }

    @ViewBuilder private var recordingContent: some View {
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
                if let featured = visibleItems.first(where: { $0.audioURL != nil }) {
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

    @ViewBuilder private var favoriteContent: some View {
        switch model.favoriteState {
        case .idle, .loading:
            SoundscapeLoadingState(title: loc(.libraryReadingRecordings))
        case .failed(let error):
            ErrorStateView(error: error) { Task { await model.reloadFavorites() } }
        case .loaded(let items) where items.isEmpty:
            EmptyStateView(title: loc(.librarySaved), detail: loc(.librarySavedEmpty), systemImage: "heart")
        case .loaded(let items):
            VStack(alignment: .leading, spacing: 0) {
                SoundscapeSectionHeader(title: loc(.librarySaved), trailing: "\(items.count)")
                    .padding(.bottom, 8)
                ForEach(items) { item in
                    FavoriteSoundscapeRow(
                        item: item,
                        play: { Task { await player.openPlayer(item, sequence: items, source: .library) } },
                        remove: {
                            Task {
                                do {
                                    _ = try await player.toggleSaved(item)
                                    await model.reloadFavorites()
                                } catch let error as AppError {
                                    favoriteActionError = error
                                } catch {
                                    favoriteActionError = .transport(String(describing: type(of: error)))
                                }
                            }
                        }
                    )
                    if item.id != items.last?.id {
                        Divider().overlay(SoundscapeTheme.line.opacity(0.65))
                    }
                }
            }
        }
    }

    private func filtered(_ items: [Soundscape]) -> [Soundscape] {
        switch filter {
        case .recordings: items
        case .publicItems: items.filter(\.isPublic)
        case .privateItems: items.filter { !$0.isPublic }
        case .favorites, .review: []
        }
    }

private struct FavoriteSoundscapeRow: View {
    let item: Soundscape
    let play: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RemoteCover(url: item.coverURL, category: item.category, isAI: item.coverIsAI, avatarSeed: item.id)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle).font(.headline).lineLimit(1)
                HStack(spacing: 6) {
                    SoundscapeAvatar(seed: item.ownerID, size: 22)
                    Text(item.authorDisplay).font(.subheadline).foregroundStyle(SoundscapeTheme.secondaryInk).lineLimit(1)
                }
                Text("\(item.locationDisplay)  ·  \(item.durationDisplay)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: remove) {
                Image(systemName: "heart.fill").frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc(.playerUnsave))
            Button(action: play) {
                Image(systemName: "play").frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(loc(.libraryPlayFeaturedRecording)) \(item.displayTitle)")
        }
        .foregroundStyle(SoundscapeTheme.ink)
        .padding(.vertical, 12)
    }
}

private struct LibraryHero: View {
    @Environment(LocaleManager.self) private var localeManager
    let item: Soundscape
    let play: () -> Void

    var body: some View {
        let locale = localeManager.current

        Button(action: play) {
            RemoteCover(url: item.coverURL, category: item.category, isAI: item.coverIsAI, avatarSeed: item.id)
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
            RemoteCover(url: item.coverURL, category: item.category, isAI: item.coverIsAI, avatarSeed: item.id)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle).font(.headline).lineLimit(1)
                Text(item.locationDisplay).font(.subheadline).foregroundStyle(SoundscapeTheme.secondaryInk).lineLimit(1)
                Text("\(durationText)  ·  \(statusLabel)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if item.audioURL != nil {
                Button(action: play) {
                    Image(systemName: "play")
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            Menu {
                if item.moderationStatus != "rejected" && item.moderationStatus != "removed" {
                    Button(item.isPublic ? loc(.libraryMakePrivate) : loc(.libraryMakePublic), action: visibility)
                }
                Button(loc(.libraryDelete), role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis.vertical").frame(width: 32, height: 44)
            }
        }
        .foregroundStyle(SoundscapeTheme.ink)
        .padding(.vertical, 12)
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private var statusLabel: String {
        switch item.moderationStatus {
        case "pending": loc(.moderationPending)
        case "rejected": loc(.moderationReject)
        case "removed": loc(.moderationRemove)
        default: item.isPublic ? loc(.libraryPublicLabel) : loc(.libraryPrivateLabel)
        }
    }

    private var durationText: String {
        let seconds = max(0, item.durationSeconds)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
}
