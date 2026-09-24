import SwiftUI
import UIKit

enum TurntableInteraction {
    static let browseThreshold: CGFloat = 11
    static let detentSpacing: CGFloat = 58

    static func mode(for translation: CGSize) -> Mode? {
        let distance = hypot(translation.width, translation.height)
        guard distance >= browseThreshold else { return nil }
        return abs(translation.height) > abs(translation.width) * 1.15 ? .browse : .park
    }

    static func detentOffset(for translation: CGSize) -> Int {
        Int((-translation.height / detentSpacing).rounded())
    }

    static func parkProgress(for translation: CGSize, startsParked: Bool) -> CGFloat {
        let initial: CGFloat = startsParked ? 1 : 0
        return min(1, max(0, initial + ((translation.width + translation.height * 0.16) / 78)))
    }

    enum Mode: Equatable {
        case browse
        case park
    }
}

enum TurntableTrackArcLayout {
    static func position(
        rowOffset: Int,
        recordCenter: CGPoint,
        recordDiameter: CGFloat
    ) -> CGPoint {
        let radius = recordDiameter * 0.4
        let arcCenter = CGPoint(
            x: recordCenter.x - recordDiameter * 0.16,
            y: recordCenter.y
        )
        let verticalOffset = CGFloat(rowOffset) * recordDiameter * 0.16
        let horizontalOffset = sqrt(max(0, radius * radius - verticalOffset * verticalOffset))
        return CGPoint(
            x: arcCenter.x + horizontalOffset,
            y: arcCenter.y + verticalOffset
        )
    }
}

enum TonearmAssemblyLayout {
    struct Geometry: Equatable {
        let pivot: CGPoint
        let control: CGPoint
        let headAnchor: CGPoint
        let headAngle: CGFloat
        let headLength: CGFloat
        let headHalfWidth: CGFloat

        var stylusTip: CGPoint {
            CGPoint(
                x: headAnchor.x + cos(headAngle) * headLength,
                y: headAnchor.y + sin(headAngle) * headLength
            )
        }

        var headshellStart: CGPoint {
            CGPoint(
                x: headAnchor.x - cos(headAngle) * headLength * 0.18,
                y: headAnchor.y - sin(headAngle) * headLength * 0.18
            )
        }

        var headshellEnd: CGPoint {
            CGPoint(
                x: headAnchor.x + cos(headAngle) * headLength * 0.58,
                y: headAnchor.y + sin(headAngle) * headLength * 0.58
            )
        }
    }

    static func geometry(
        in size: CGSize,
        recordDiameter: CGFloat,
        recordTop: CGFloat,
        parkProgress: CGFloat,
        browseOffset: CGFloat
    ) -> Geometry {
        let pivot = CGPoint(x: size.width - 64, y: recordTop + 54)
        let center = CGPoint(x: recordDiameter * 0.26, y: recordTop + recordDiameter * 0.5)
        let radius = recordDiameter * 0.43
        let verticalDistance = -min(2, max(-2, browseOffset)) * recordDiameter * 0.16
        let onRecord = CGPoint(x: center.x + sqrt(radius * radius - verticalDistance * verticalDistance),
                               y: center.y + verticalDistance)
        let parked = CGPoint(x: size.width - 22, y: recordTop + recordDiameter * 0.82)
        let tip = CGPoint(x: onRecord.x + (parked.x - onRecord.x) * parkProgress,
                          y: onRecord.y + (parked.y - onRecord.y) * parkProgress)
        let headAngle = atan2(tip.y - pivot.y, tip.x - pivot.x)
        let headLength = min(42, max(30, recordDiameter * 0.075))
        let headAnchor = CGPoint(x: tip.x - cos(headAngle) * headLength,
                                 y: tip.y - sin(headAngle) * headLength)
        let control = CGPoint(
            x: size.width + 3,
            y: pivot.y + ((headAnchor.y - pivot.y) * 0.49)
        )

        return Geometry(
            pivot: pivot,
            control: control,
            headAnchor: headAnchor,
            headAngle: headAngle,
            headLength: headLength,
            headHalfWidth: min(8, max(5.5, recordDiameter * 0.013))
        )
    }

}

enum TurntableNavigationGesture {
    private static let threshold: CGFloat = 56
    private static let horizontalDominance: CGFloat = 1.15
    private static let tonearmExclusionStart: CGFloat = 0.78
    private static let leadingEdgeActivationWidth: CGFloat = 44

    static func shouldDismissPlayer(
        translation: CGSize,
        startX: CGFloat,
        width: CGFloat
    ) -> Bool {
        tracksDismissPlayer(translation: translation, startX: startX, width: width)
            && translation.width <= -threshold
    }

    static func tracksDismissPlayer(
        translation: CGSize,
        startX: CGFloat,
        width: CGFloat
    ) -> Bool {
        guard width > 0,
              startX >= 0,
              startX <= width * tonearmExclusionStart,
              translation.width < 0 else {
            return false
        }
        return abs(translation.width) > abs(translation.height) * horizontalDominance
    }

    static func shouldPresentPlayer(
        translation: CGSize,
        startX: CGFloat,
        width: CGFloat,
        requiresLeadingEdge: Bool = false
    ) -> Bool {
        tracksPresentPlayer(translation: translation, startX: startX, width: width)
            && (!requiresLeadingEdge || startX <= leadingEdgeActivationWidth)
            && translation.width >= threshold
    }

    static func tracksPresentPlayer(
        translation: CGSize,
        startX: CGFloat,
        width: CGFloat
    ) -> Bool {
        guard width > 0,
              startX >= 0,
              startX <= width,
              translation.width > 0 else {
            return false
        }
        return translation.width > abs(translation.height) * horizontalDominance
    }
}

enum TurntablePlayerLayout {
    static let metadataGap: CGFloat = 44
    static let metadataHeight: CGFloat = 126
    static let metadataBottomInset: CGFloat = 56

    static func recordDiameter(in size: CGSize) -> CGFloat {
        min(size.width * 1.28, size.height * 0.54)
    }

    static func recordTop(in size: CGSize, recordDiameter: CGFloat) -> CGFloat {
        let maximumTop = size.height
            - recordDiameter
            - metadataGap
            - metadataHeight
            - metadataBottomInset
        return max(116, min(size.height * 0.24, maximumTop))
    }

    static func metadataFrame(
        in size: CGSize,
        recordTop: CGFloat,
        recordDiameter: CGFloat
    ) -> CGRect {
        let width = max(0, size.width - 56)
        let preferredTop = size.height - metadataBottomInset - metadataHeight
        let minimumTop = recordTop + recordDiameter + metadataGap
        let top = max(0, max(preferredTop, minimumTop))
        return CGRect(x: (size.width - width) / 2, y: top, width: width, height: metadataHeight)
    }
}

struct TurntablePlayerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(LocaleManager.self) private var localeManager
    let soundscape: Soundscape
    let player: AudioPlayerController
    let moderation: any ModerationRepository
    let session: IdentitySession
    let onCreatorBlocked: () -> Void

    @State private var interactionMode: TurntableInteraction.Mode?
    @State private var startsParked = false
    @State private var parkProgress: CGFloat = 0
    @State private var browseOffset = 0
    @State private var showsTrackList = false
    @State private var showsDetails = false
    @State private var isSwitching = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var needleRaised = false
    @State private var selection = TonearmSelection(ids: [], currentID: nil)
    @State private var dragStartSlot: Int?
    @State private var edgeDirection = 0
    @State private var edgeTask: Task<Void, Never>?
    @State private var dragPosition: CGFloat = 0
    @State private var dragStartPark: CGFloat = 0
    @State private var catalogError: AppError?
    @State private var candidates: [Int: Soundscape] = [:]
    @State private var detailsDetent: PresentationDetent = .fraction(0.62)
    @State private var selectedFeedback: PlayerFeedbackChoice?
    @State private var safetyNotice: String?
    @State private var safetyError: AppError?
    @State private var showsIdentityForBlock = false
    @State private var confirmsBlock = false
    @GestureState private var gestureActive = false

    var body: some View {
        let locale = localeManager.current

        GeometryReader { proxy in
            let size = proxy.size
            let recordDiameter = TurntablePlayerLayout.recordDiameter(in: size)
            let recordTop = TurntablePlayerLayout.recordTop(
                in: size,
                recordDiameter: recordDiameter
            )
            let recordLeft = -recordDiameter * 0.24
            let metadataFrame = TurntablePlayerLayout.metadataFrame(
                in: size,
                recordTop: recordTop,
                recordDiameter: recordDiameter
            )
            let recordCenter = CGPoint(
                x: recordLeft + recordDiameter / 2,
                y: recordTop + recordDiameter / 2
            )

            ZStack(alignment: .topLeading) {
                SoundscapeTheme.playerBackground.ignoresSafeArea()

                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityLabel(loc(.playerTurntable))
                    .accessibilityIdentifier("turntable-player")
                    .allowsHitTesting(false)

                VinylRecordArtwork(isRotating: player.isPlaying || (player.isBuffering && !startsParked), showsPlaybackGroove: !needleRaised && player.isPlaying)
                    .frame(width: recordDiameter, height: recordDiameter)
                    .offset(x: recordLeft, y: recordTop)
                    .opacity(showsTrackList ? 0.4 : 1)

                if showsTrackList {
                    trackList(in: size, recordCenter: recordCenter, recordDiameter: recordDiameter)
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .center)))
                }

                tonearm(in: size, recordDiameter: recordDiameter, recordTop: recordTop)

                header(in: size)
                    .padding(.top, 12)

                if !showsTrackList {
                    metadata
                        .frame(
                            width: metadataFrame.width,
                            height: metadataFrame.height,
                            alignment: .bottomLeading
                        )
                        .position(
                            x: metadataFrame.midX,
                            y: metadataFrame.midY
                        )
                        .transition(.opacity)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(loc(parkProgress >= 0.52 ? .playerReleaseToPause : .playerNeedleRaised)).font(.headline)
                        Text(loc(.playerBrowseHint))
                            .font(.subheadline)
                            .foregroundStyle(SoundscapeTheme.playerSecondaryInk)
                    }
                    .foregroundStyle(SoundscapeTheme.playerInk)
                    .frame(width: metadataFrame.width, alignment: .leading)
                    .position(x: metadataFrame.midX, y: metadataFrame.midY)
                }

                if let error = player.error ?? catalogError {
                    playbackError(error)
                        .padding(.horizontal, 20)
                        .offset(y: size.height - 86)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .coordinateSpace(name: "turntable-surface")
        }
        .background(SoundscapeTheme.playerBackground)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .onAppear {
            startsParked = player.phase == .paused
            parkProgress = startsParked ? 1 : 0
            needleRaised = startsParked
            selection = TonearmSelection(ids: cacheCandidates(), currentID: player.current?.id)
        }
        .task {
            do {
                try await player.loadVinylCatalog()
                if !player.isBrowsing {
                    selection = TonearmSelection(ids: cacheCandidates(), currentID: player.current?.id)
                }
            } catch let error as AppError { catalogError = error }
            catch { catalogError = .transport(String(describing: type(of: error))) }
        }
        .onChange(of: player.current?.id) { _, _ in
            guard !isSwitching, !player.isBrowsing else { return }
            stopEdgeScroll()
            needleRaised = false
            showsTrackList = false
            browseOffset = 0
            dragPosition = 0
            selection = TonearmSelection(ids: cacheCandidates(), currentID: player.current?.id)
        }
        .onChange(of: player.phase) { _, phase in
            if phase == .playing, needleRaised, !player.isBrowsing {
                needleRaised = false
                showsTrackList = false
                stopEdgeScroll()
            }
            guard !player.isBrowsing else { return }
            let parked = phase == .paused
            withAnimation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.84)) {
                startsParked = parked
                parkProgress = parked ? 1 : 0
                needleRaised = parked
            }
        }
        .sheet(isPresented: $showsDetails) {
            detailsSheet
        }
        .sheet(isPresented: $showsIdentityForBlock) { IdentitySheet(session: session) }
        .confirmationDialog(loc(.moderationBlock), isPresented: $confirmsBlock) {
            Button(loc(.moderationBlock), role: .destructive) { Task { await blockCurrentCreator() } }
        }
        .onChange(of: showsTrackList) { _, isVisible in
            if isVisible { player.recordVisibleRecommendationWindow() }
        }
        .onChange(of: player.presentedSoundscape) { _, value in
            if value == nil { cancelBrowse() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { cancelBrowse() }
        }
        .onChange(of: gestureActive) { _, active in
            if !active, dragStartSlot != nil { cancelBrowse() }
        }
        .onDisappear { cancelBrowse() }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private func header(in size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Button {
                player.dismissPlayer(stopPlayback: false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(loc(.generalBack))
            .accessibilityIdentifier("turntable-back")
            .position(x: 34, y: 22)

            Text(showsTrackList ? loc(.playerSelectTrack) : soundscape.displayTitle)
                .font(.headline.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: max(0, size.width - 144))
                .transition(.opacity)
                .position(x: size.width / 2, y: 22)

            Button {
                Task { _ = await player.toggleSavedCurrent() }
            } label: {
                Image(systemName: player.savedSoundscapeIDs.contains(soundscape.id) ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .regular))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(player.savedSoundscapeIDs.contains(soundscape.id) ? loc(.playerUnsave) : loc(.playerSave))
            .position(x: size.width - 42, y: 22)
        }
        .frame(width: size.width, height: 44, alignment: .topLeading)
        .foregroundStyle(SoundscapeTheme.playerInk)
    }

    private var metadata: some View {
        ZStack(alignment: .bottomTrailing) {
            Button {
                showsDetails = true
            } label: {
                VStack(alignment: .leading, spacing: 7) {
                    Text(soundscape.displayTitle)
                        .font(.system(size: 27, weight: .semibold))
                        .tracking(-0.55)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(player.sourceLine)
                        .font(.subheadline)
                        .foregroundStyle(SoundscapeTheme.playerSecondaryInk)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.trailing, 126)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(soundscape.displayTitle), \(player.sourceLine)")
            .accessibilityValue(playbackStateLabel)
            .accessibilityHint(loc(.playerOpenDetailsHint))
            .accessibilityIdentifier("turntable-metadata")

            playbackModeControl
                .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .foregroundStyle(SoundscapeTheme.playerInk)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: soundscape.id)
    }

    private var playbackStateLabel: String {
        player.isBuffering ? loc(.playerLoading) : (player.isPlaying ? loc(.playerNeedleOnRecord) : loc(.playerNeedleParked))
    }

    private var playbackModeControl: some View {
        Menu {
            ForEach(AudioPlayerController.PlaybackMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) {
                        player.setPlaybackMode(mode)
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Label(
                        playbackModeTitle(mode),
                        systemImage: mode == player.playbackMode ? "checkmark" : playbackModeIcon(mode)
                    )
                }
                .accessibilityIdentifier("playback-mode-\(mode.rawValue)")
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: playbackModeIcon(player.playbackMode))
                    .font(.caption.weight(.semibold))
                Text(playbackModeTitle(player.playbackMode))
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.7)
            }
            .foregroundStyle(SoundscapeTheme.playerInk)
            .padding(.horizontal, 11)
            .frame(minHeight: 44)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(loc(.playerPlaybackMode)): \(playbackModeTitle(player.playbackMode))")
        .accessibilityHint(loc(.playerPlaybackModeHint))
        .accessibilityIdentifier("playback-mode")
    }

    private func playbackModeTitle(_ mode: AudioPlayerController.PlaybackMode) -> String {
        switch mode {
        case .repeatOne: loc(.playerRepeatOne)
        case .continuous: loc(.playerContinuous)
        case .shuffle: loc(.playerShuffle)
        }
    }

    private func playbackModeIcon(_ mode: AudioPlayerController.PlaybackMode) -> String {
        switch mode {
        case .repeatOne: "repeat.1"
        case .continuous: "repeat"
        case .shuffle: "shuffle"
        }
    }

    private func trackList(
        in size: CGSize,
        recordCenter: CGPoint,
        recordDiameter: CGFloat
    ) -> some View {
        return ZStack(alignment: .topLeading) {
            ForEach(selection.slots.values.sorted(), id: \.self) { trackID in
                let rowOffset = selection.slots.first(where: { $0.value == trackID })?.key ?? 0
                if let id = selection.slots[rowOffset],
                   let candidate = candidates[id] {
                    let selected = rowOffset == selection.selectedSlot
                    let point = TurntableTrackArcLayout.position(
                        rowOffset: rowOffset,
                        recordCenter: recordCenter,
                        recordDiameter: recordDiameter
                    )
                    let leadingEdge = 24 + CGFloat(2 - abs(rowOffset)) * 10
                    let rowWidth = max(118, size.width * 0.53 - leadingEdge)
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(selected ? 0.95 : 0.72), lineWidth: selected ? 2 : 1.25)
                            if selected {
                                Circle().fill(.white).padding(6)
                            }
                        }
                        .frame(width: 18, height: 18)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(candidate.displayTitle)
                                .font(.subheadline.weight(selected ? .semibold : .regular))
                                .lineLimit(1)
                            Text(candidate.locationDisplay)
                                .font(.caption)
                                .foregroundStyle(SoundscapeTheme.playerSecondaryInk)
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(.white)
                    .opacity(selected ? 1 : 0.72)
                    .frame(width: rowWidth, alignment: .leading)
                    .frame(minHeight: 44)
                    .position(x: leadingEdge + rowWidth / 2, y: point.y)
                    .transition(.opacity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(selected ? "\(loc(.playerSelectedTrack)) \(candidate.displayTitle)" : candidate.displayTitle)
                    .contentShape(Rectangle())
                    .onTapGesture { selectGroove(rowOffset); placeNeedle() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("tonearm-track-\(rowOffset)")
                    .accessibilityAction { selectGroove(rowOffset); placeNeedle() }
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.86), value: browseOffset)
    }

    private func tonearm(in size: CGSize, recordDiameter: CGFloat, recordTop: CGFloat) -> some View {
        let geometry = TonearmAssemblyLayout.geometry(
            in: size, recordDiameter: recordDiameter, recordTop: recordTop,
            parkProgress: parkProgress, browseOffset: -dragPosition
        )
        return ZStack(alignment: .topLeading) {
            TonearmDrawing(
                size: size, recordDiameter: recordDiameter, recordTop: recordTop,
                parkProgress: parkProgress,
                browsePosition: -dragPosition
            )
            .offset(x: needleRaised ? -4 : 0, y: needleRaised ? -8 : 0)
            .shadow(color: .black.opacity(needleRaised ? 0.7 : 0), radius: 8, x: 6, y: 12)
            .allowsHitTesting(false)

            Color.clear
                .frame(width: 88, height: 88)
                .contentShape(Rectangle())
                .position(x: min(size.width - 44, max(44, geometry.headAnchor.x)), y: geometry.headAnchor.y)
                .gesture(tonearmGesture(detentSpacing: recordDiameter * 0.16))
                .accessibilityElement()
                .accessibilityLabel(loc(.playerNeedle))
                .accessibilityIdentifier("tonearm-control")
                .accessibilityValue(player.isBrowsing ? loc(parkProgress >= 0.52 ? .playerReleaseToPause : .playerNeedleRaised) : (parkProgress > 0.5 ? loc(.playerNeedlePaused) : loc(.playerNeedlePlaying)))
                .accessibilityHint(loc(.playerNeedleGestureHint))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { toggleNeedle() }
                .accessibilityAction(named: loc(.playerPause)) { parkNeedle() }
                .accessibilityAction(named: loc(.playerPlay)) { placeNeedle() }
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: adjustSelection(1)
                    case .decrement: adjustSelection(-1)
                    @unknown default: break
                    }
                }
        }
    }

    private func tonearmGesture(detentSpacing: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .named("turntable-surface"))
            .updating($gestureActive) { _, active, _ in active = true }
            .onChanged { value in
                guard !isSwitching else { return }
                if dragStartSlot == nil {
                    dragStartPark = parkProgress
                    liftNeedle()
                    dragStartSlot = selection.selectedSlot
                }
                let position = CGFloat(dragStartSlot ?? 0) + value.translation.height / detentSpacing
                let previous = selection.selectedID
                var transaction = Transaction()
                transaction.animation = nil
                withTransaction(transaction) {
                    dragPosition = min(2, max(-2, position))
                    selection.select(slot: Int(dragPosition.rounded()))
                    parkProgress = min(1, max(0, dragStartPark + value.translation.width / 78))
                }
                if selection.selectedID != previous { UISelectionFeedbackGenerator().selectionChanged() }
                startEdgeScroll(parkProgress > 0.35 ? 0 : (position >= 1.85 ? 1 : (position <= -1.85 ? -1 : 0)))
            }
            .onEnded { _ in
                guard dragStartSlot != nil else { return }
                stopEdgeScroll()
                dragStartSlot = nil
                if parkProgress >= 0.52 { parkNeedle() }
                else { placeNeedle() }
            }
    }

    private func selectGroove(_ slot: Int) {
        guard needleRaised else { return }
        let previous = selection.selectedID
        withAnimation(reduceMotion ? nil : .interactiveSpring(response: 0.24, dampingFraction: 0.88)) {
            selection.select(slot: slot)
            browseOffset = selection.selectedSlot
            dragPosition = CGFloat(selection.selectedSlot)
            showsTrackList = true
            parkProgress = 0
        }
        if selection.selectedID != previous { UISelectionFeedbackGenerator().selectionChanged() }
    }

    private func adjustSelection(_ direction: Int) {
        if !needleRaised { liftNeedle() }
        let occupied = selection.slots.keys.sorted()
        let next = direction > 0
            ? occupied.first(where: { $0 > selection.selectedSlot })
            : occupied.last(where: { $0 < selection.selectedSlot })
        if let next { selectGroove(next) }
        else { _ = selection.advanceEdge(direction) }
        placeNeedle()
    }

    private func startEdgeScroll(_ direction: Int) {
        guard direction != edgeDirection else { return }
        stopEdgeScroll()
        guard direction != 0, candidates.count > 5 else { return }
        edgeDirection = direction
        edgeTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(550))
                while !Task.isCancelled, player.isBrowsing, dragStartSlot != nil,
                      player.presentedSoundscape != nil, scenePhase == .active {
                    var changed = false
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                        changed = selection.advanceEdge(direction)
                    }
                    if !changed { break }
                    UISelectionFeedbackGenerator().selectionChanged()
                    try await Task.sleep(for: .milliseconds(380))
                }
            } catch { /* Cancellation ends edge dwell immediately. */ }
        }
    }

    private func stopEdgeScroll() {
        edgeTask?.cancel()
        edgeTask = nil
        edgeDirection = 0
    }

    private func toggleNeedle() {
        guard !isSwitching else { return }
        if player.isPlaying { parkNeedle() } else { placeNeedle() }
    }

    private func liftNeedle() {
        guard !isSwitching else { return }
        stopEdgeScroll()
        let ids = cacheCandidates()
        if selection.selectedID != player.current?.id || selection.slots.isEmpty {
            selection = TonearmSelection(ids: ids.isEmpty ? [soundscape.id] : ids, currentID: player.current?.id)
        }
        player.setBrowsing(true)
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.82)) {
            needleRaised = true
            showsTrackList = true
            browseOffset = 0
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func parkNeedle() {
        stopEdgeScroll()
        player.pause()
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.88)) {
            needleRaised = true
            startsParked = true
            parkProgress = 1
            showsTrackList = false
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func placeNeedle() {
        guard !isSwitching else { return }
        stopEdgeScroll()
        let candidate = selection.selectedID.flatMap { candidates[$0] } ?? player.current
        guard let candidate else { return }
        isSwitching = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.88)) {
            needleRaised = false
            startsParked = false
            parkProgress = 0
            showsTrackList = false
            dragPosition = CGFloat(selection.selectedSlot)
        }
        Task { @MainActor in
            await player.commitNeedleSelection(candidate)
            isSwitching = false
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func cancelBrowse() {
        stopEdgeScroll()
        dragStartSlot = nil
        interactionMode = nil
        guard player.isBrowsing else { return }
        player.setBrowsing(false)
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.88)) {
            needleRaised = !player.isPlaying
            startsParked = !player.isPlaying
            parkProgress = startsParked ? 1 : 0
            showsTrackList = false
            dragPosition = 0
        }
    }

    private func cacheCandidates() -> [Int] {
        let stream = player.vinylStream
        candidates = Dictionary(uniqueKeysWithValues: stream.map { ($0.id, $0) })
        return stream.map(\.id)
    }
    private func playbackError(_ error: AppError) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
            Text(error.userMessage).font(.caption).lineLimit(2)
            Spacer(minLength: 4)
            Button(loc(.generalDismiss)) { player.dismissError(); catalogError = nil }
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.16), lineWidth: 1) }
    }

    private var detailsSheet: some View {
        ZStack {
            SoundscapeTheme.playerBackground.opacity(0.38).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Text(loc(.playerDetails))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SoundscapeTheme.playerSecondaryInk)
                        Spacer()
                        Button(loc(.generalDone)) { showsDetails = false }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SoundscapeTheme.playerInk)
                            .frame(minWidth: 54, minHeight: 44)
                            .background(.thinMaterial, in: Capsule())
                            .accessibilityIdentifier("player-details-done")
                    }

                    Text(soundscape.displayTitle)
                        .font(.system(size: 36, weight: .semibold))
                        .tracking(-1.2)
                        .foregroundStyle(SoundscapeTheme.playerInk)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: detailColumns, spacing: 12) {
                        detailFact(title: loc(.playerAuthor), value: soundscape.authorDisplay, icon: "person", identifier: "player-detail-author")
                        detailFact(title: loc(.playerLocation), value: soundscape.locationDisplay, icon: "location", identifier: "player-detail-location")
                        detailFact(title: loc(.playerDuration), value: durationText, icon: "waveform", identifier: "player-detail-duration")
                        detailFact(title: loc(.playerRecordedAt), value: recordingDateText, icon: "calendar", identifier: "player-detail-date")
                    }

                    if !soundscape.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(loc(.playerMemo))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SoundscapeTheme.playerSecondaryInk)
                            Text(soundscape.description)
                                .font(.body)
                                .foregroundStyle(SoundscapeTheme.playerInk.opacity(0.9))
                                .lineSpacing(5)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityIdentifier("player-detail-memo")
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text(loc(.playerFeedbackTitle))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(SoundscapeTheme.playerInk)
                        Text(loc(.playerFeedbackDetail))
                            .font(.subheadline)
                            .foregroundStyle(SoundscapeTheme.playerSecondaryInk)

                        feedbackButtons
                    }
                    .padding(18)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if let safetyNotice {
                        Text(safetyNotice)
                            .foregroundStyle(SoundscapeTheme.playerInk)
                            .accessibilityIdentifier("moderation-feedback")
                    }
                    if let safetyError {
                        Text(safetyError.userMessage)
                            .foregroundStyle(SoundscapeTheme.playerInk)
                    }
                    if soundscape.ownerID != session.user?.id {
                        safetyActions
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SoundscapeTheme.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 38)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.fraction(0.62), .large], selection: $detailsDetent)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(32)
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.62)))
        .presentationContentInteraction(.resizes)
        .preferredColorScheme(.dark)
        .onAppear { detailsDetent = .fraction(0.62) }
        .onChange(of: soundscape.id) { _, _ in selectedFeedback = nil }
    }

    private func detailFact(title: String, value: String, icon: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoundscapeTheme.playerSecondaryInk)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SoundscapeTheme.playerInk)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private var detailColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var safetyActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Menu {
                Button(loc(.moderationHarassment)) { Task { await sendReport(.moderationHarassment) } }
                Button(loc(.moderationHate)) { Task { await sendReport(.moderationHate) } }
                Button(loc(.moderationCopyright)) { Task { await sendReport(.moderationCopyright) } }
                Button(loc(.moderationOther)) { Task { await sendReport(.moderationOther) } }
            } label: {
                Label(loc(.moderationReport), systemImage: "flag")
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            }
            .accessibilityIdentifier("report-soundscape")
            Button {
                guard session.user != nil else { showsIdentityForBlock = true; return }
                confirmsBlock = true
            } label: {
                Label(loc(.moderationBlock), systemImage: "person.crop.circle.badge.xmark")
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            }
            .accessibilityIdentifier("block-creator")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(SoundscapeTheme.playerInk)
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func blockCurrentCreator() async {
        do {
            try await moderation.block(creatorID: soundscape.ownerID)
            player.removeCreator(soundscape.ownerID)
            onCreatorBlocked()
        } catch let appError as AppError { safetyError = appError }
        catch { safetyError = .transport(String(describing: type(of: error))) }
    }

    private func sendReport(_ reason: SoundscapeLocale) async {
        do {
            try await moderation.report(soundscapeID: soundscape.id, reason: loc(reason))
            safetyNotice = loc(.moderationReported)
        } catch let appError as AppError { safetyError = appError }
        catch { safetyError = .transport(String(describing: type(of: error))) }
    }

    private var feedbackButtons: some View {
        VStack(spacing: 10) {
            feedbackButton(.resonates, title: loc(.playerResonates), icon: "heart")
            feedbackButton(.notNow, title: loc(.playerNotNow), icon: "clock")
            feedbackButton(.lessLikeThis, title: loc(.playerLessLikeThis), icon: "hand.thumbsdown")
        }
    }

    private func feedbackButton(_ choice: PlayerFeedbackChoice, title: String, icon: String) -> some View {
        Button {
            selectedFeedback = choice
            switch choice {
            case .resonates:
                player.recordResonanceFeedback(ResonanceFeedback(kind: .resonated, listenedSeconds: player.elapsedSeconds))
            case .notNow:
                Task { await player.skipCurrent(reason: .notNow) }
            case .lessLikeThis:
                Task { await player.skipCurrent(reason: .dislike) }
            }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedFeedback == choice ? "checkmark.circle.fill" : icon)
                    .frame(width: 22)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(selectedFeedback == choice ? SoundscapeTheme.playerBackground : SoundscapeTheme.playerInk)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(selectedFeedback == choice ? SoundscapeTheme.playerInk : .white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(selectedFeedback == choice ? 0 : 0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(choice.accessibilityIdentifier)
    }

    private var durationText: String {
        let seconds = max(0, soundscape.durationSeconds)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var recordingDateText: String {
        let raw = soundscape.createdAt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return loc(.playerUnknownDate) }
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = input.date(from: raw) else { return raw }
        let output = DateFormatter()
        output.locale = Locale(identifier: localeManager.current.rawValue)
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }
}

private enum PlayerFeedbackChoice: Equatable {
    case resonates
    case notNow
    case lessLikeThis

    var accessibilityIdentifier: String {
        switch self {
        case .resonates: "recommendation-resonates"
        case .notNow: "recommendation-not-now"
        case .lessLikeThis: "recommendation-less-like-this"
        }
    }
}
