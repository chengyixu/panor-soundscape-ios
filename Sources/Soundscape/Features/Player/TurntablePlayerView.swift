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
        browseOffset: Int
    ) -> Geometry {
        let pivot = CGPoint(x: size.width - 64, y: recordTop + 54)
        let restingStylusAnchor = CGPoint(x: size.width - 82, y: recordTop + recordDiameter * 0.79)
        let parked = CGPoint(x: size.width - 18, y: recordTop + recordDiameter * 0.88)

        // Browsing is a rotation about the pivot, not a vertical translation.
        // The prior implementation changed only `y`, which made the stylus
        // travel straight up and down. Keeping the arm radius constant makes
        // the contact point follow the pivot arc; its movement is therefore
        // tangent to the record at every detent.
        let armRadius = hypot(
            restingStylusAnchor.x - pivot.x,
            restingStylusAnchor.y - pivot.y
        )
        let requestedY = restingStylusAnchor.y - CGFloat(browseOffset) * 18
        let limitedY = min(
            pivot.y + armRadius - 1,
            max(pivot.y - armRadius + 1, requestedY)
        )
        let verticalDistance = limitedY - pivot.y
        let horizontalDistance = sqrt(max(0, armRadius * armRadius - verticalDistance * verticalDistance))
        let onRecord = CGPoint(
            x: pivot.x - horizontalDistance,
            y: limitedY
        )
        let headAnchor = CGPoint(
            x: onRecord.x + ((parked.x - onRecord.x) * parkProgress),
            y: onRecord.y + ((parked.y - onRecord.y) * parkProgress)
        )
        let control = CGPoint(
            x: size.width + 3,
            y: pivot.y + ((headAnchor.y - pivot.y) * 0.49)
        )
        let armAngle = atan2(onRecord.y - pivot.y, onRecord.x - pivot.x)
        // The headshell/stylus stays perpendicular to the pivot radius. This
        // gives the needle a tangential orientation while it follows the arc.
        let headAngle = armAngle + (.pi / 2)

        return Geometry(
            pivot: pivot,
            control: control,
            headAnchor: headAnchor,
            headAngle: headAngle,
            headLength: min(42, max(30, recordDiameter * 0.075)),
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

struct TurntablePlayerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    let soundscape: Soundscape
    let player: AudioPlayerController

    @State private var interactionMode: TurntableInteraction.Mode?
    @State private var startsParked = false
    @State private var parkProgress: CGFloat = 0
    @State private var browseOffset = 0
    @State private var lastHapticOffset = 0
    @State private var showsTrackList = false
    @State private var showsDetails = false
    @State private var isSwitching = false

    var body: some View {
        let locale = localeManager.current

        GeometryReader { proxy in
            let size = proxy.size
            let recordDiameter = min(size.width * 1.28, size.height * 0.59)
            let recordTop = max(92, size.height * 0.12)
            let recordLeft = -recordDiameter * 0.24
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

                VinylRecordArtwork(isRotating: player.isPlaying)
                    .frame(width: recordDiameter, height: recordDiameter)
                    .offset(x: recordLeft, y: recordTop)
                    .opacity(isSwitching ? 0.55 : 1)

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
                            width: max(0, size.width - 56),
                            height: 150,
                            alignment: .topLeading
                        )
                        .position(
                            x: size.width / 2,
                            y: min(size.height - 113, recordTop + recordDiameter + 93)
                        )
                        .transition(.opacity)
                }

                if let error = player.error {
                    playbackError(error)
                        .padding(.horizontal, 20)
                        .offset(y: size.height - 86)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .background(SoundscapeTheme.playerBackground)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .onAppear {
            startsParked = player.phase == .paused
            parkProgress = startsParked ? 1 : 0
        }
        .onChange(of: player.phase) { _, phase in
            guard interactionMode == nil else { return }
            let parked = phase == .paused
            withAnimation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.84)) {
                startsParked = parked
                parkProgress = parked ? 1 : 0
            }
        }
        .sheet(isPresented: $showsDetails) {
            detailsSheet
        }
        .onChange(of: showsTrackList) { _, isVisible in
            if isVisible { player.recordVisibleRecommendationWindow() }
        }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { showsDetails = true }
        .foregroundStyle(SoundscapeTheme.playerInk)
        .opacity(isSwitching ? 0 : 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: isSwitching)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(soundscape.displayTitle), \(player.sourceLine)")
        .accessibilityValue(playbackStateLabel)
        .accessibilityHint(loc(.playerOpenDetailsHint))
        .accessibilityIdentifier("turntable-metadata")
    }

    private var playbackStateLabel: String {
        player.isBuffering ? loc(.playerLoading) : (player.isPlaying ? loc(.playerNeedleOnRecord) : loc(.playerNeedleParked))
    }

    private func trackList(
        in size: CGSize,
        recordCenter: CGPoint,
        recordDiameter: CGFloat
    ) -> some View {
        let topPoint = TurntableTrackArcLayout.position(
            rowOffset: -2,
            recordCenter: recordCenter,
            recordDiameter: recordDiameter
        )
        let centerPoint = TurntableTrackArcLayout.position(
            rowOffset: 0,
            recordCenter: recordCenter,
            recordDiameter: recordDiameter
        )
        let bottomPoint = TurntableTrackArcLayout.position(
            rowOffset: 2,
            recordCenter: recordCenter,
            recordDiameter: recordDiameter
        )

        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: topPoint)
                path.addQuadCurve(
                    to: bottomPoint,
                    control: CGPoint(
                        x: centerPoint.x * 2 - topPoint.x,
                        y: centerPoint.y
                    )
                )
            }
            .stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

            ForEach(-2...2, id: \.self) { rowOffset in
                if let candidate = player.candidate(relativeOffset: browseOffset + rowOffset) {
                    let selected = rowOffset == 0
                    let point = TurntableTrackArcLayout.position(
                        rowOffset: rowOffset,
                        recordCenter: recordCenter,
                        recordDiameter: recordDiameter
                    )
                    let leadingEdge = point.x - 14.5
                    let rowWidth = max(118, size.width - leadingEdge - 18)
                    HStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(selected ? 0.95 : 0.72), lineWidth: selected ? 2 : 1.25)
                            if selected {
                                Circle().fill(.white).padding(6)
                            }
                        }
                        .frame(width: 29, height: 29)

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
                    .position(x: leadingEdge + rowWidth / 2, y: point.y)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(selected ? "\(loc(.playerSelectedTrack)) \(candidate.displayTitle)" : candidate.displayTitle)
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.86), value: browseOffset)
    }

    private func tonearm(in size: CGSize, recordDiameter: CGFloat, recordTop: CGFloat) -> some View {
        let geometry = TonearmAssemblyLayout.geometry(
            in: size,
            recordDiameter: recordDiameter,
            recordTop: recordTop,
            parkProgress: parkProgress,
            browseOffset: browseOffset
        )

        return ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                var assembly = Path()
                assembly.move(to: geometry.pivot)
                assembly.addQuadCurve(to: geometry.headAnchor, control: geometry.control)
                assembly.addLine(to: geometry.stylusTip)
                context.stroke(
                    assembly,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: geometry.pivot.x - 24,
                        y: geometry.pivot.y - 24,
                        width: 48,
                        height: 48
                    )),
                    with: .color(.white)
                )
                var headshell = Path()
                headshell.move(to: geometry.headshellStart)
                headshell.addLine(to: geometry.headshellEnd)
                context.stroke(
                    headshell,
                    with: .color(.white),
                    style: StrokeStyle(
                        lineWidth: geometry.headHalfWidth * 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)

            Color.clear
                .frame(width: 112, height: recordDiameter * 0.92)
                .contentShape(Rectangle())
                .position(x: size.width - 52, y: recordTop + recordDiameter * 0.52)
                .gesture(tonearmGesture)
                .accessibilityElement()
                .accessibilityLabel(loc(.playerNeedle))
                .accessibilityIdentifier("tonearm-control")
                .accessibilityValue(parkProgress > 0.5 ? loc(.playerNeedlePaused) : loc(.playerNeedlePlaying))
                .accessibilityHint(loc(.playerNeedleGestureHint))
                .accessibilityAction(named: loc(.playerPause)) { parkNeedle() }
                .accessibilityAction(named: loc(.playerPlay)) { placeNeedle() }
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: Task { await player.next() }
                    case .decrement:
                        if let candidate = player.candidate(relativeOffset: -1) {
                            Task { await player.selectCandidate(candidate) }
                        }
                    @unknown default: break
                    }
                }
        }
    }

    private var tonearmGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if interactionMode == nil {
                    interactionMode = TurntableInteraction.mode(for: value.translation)
                    if interactionMode == .browse {
                        startsParked = false
                        lastHapticOffset = 0
                        player.setBrowsing(true)
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                            showsTrackList = true
                        }
                    }
                }

                switch interactionMode {
                case .browse:
                    let offset = TurntableInteraction.detentOffset(for: value.translation)
                    if offset != lastHapticOffset {
                        UISelectionFeedbackGenerator().selectionChanged()
                        lastHapticOffset = offset
                    }
                    browseOffset = offset
                    parkProgress = 0
                case .park:
                    parkProgress = TurntableInteraction.parkProgress(
                        for: value.translation,
                        startsParked: startsParked
                    )
                case nil:
                    break
                }
            }
            .onEnded { _ in
                switch interactionMode {
                case .browse:
                    finishBrowsing()
                case .park:
                    finishParking()
                case nil:
                    break
                }
                interactionMode = nil
            }
    }

    private func finishBrowsing() {
        player.setBrowsing(false)
        let selected = player.candidate(relativeOffset: browseOffset)
        let changed = browseOffset != 0 && selected?.id != soundscape.id
        if changed, let selected {
            isSwitching = true
            Task {
                await player.selectCandidate(selected)
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 420))
                await MainActor.run {
                    isSwitching = false
                    browseOffset = 0
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) {
                        showsTrackList = false
                    }
                }
            }
        } else {
            browseOffset = 0
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                showsTrackList = false
            }
        }
    }

    private func finishParking() {
        if parkProgress >= 0.52 {
            parkNeedle()
        } else {
            placeNeedle()
        }
    }

    private func parkNeedle() {
        startsParked = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82)) {
            parkProgress = 1
        }
        player.pause()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func placeNeedle() {
        startsParked = false
        withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82)) {
            parkProgress = 0
        }
        if let current = player.current, !player.isPlaying, !player.isBuffering {
            Task { await player.toggle(current) }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func playbackError(_ error: AppError) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
            Text(error.userMessage).font(.caption).lineLimit(2)
            Spacer(minLength: 4)
            Button(loc(.generalDismiss)) { player.dismissError() }
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.16), lineWidth: 1) }
    }

    private var detailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(soundscape.displayTitle)
                        .font(.system(size: 34, weight: .bold))
                        .tracking(-1)
                    Text(player.sourceLine)
                        .font(.headline)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                    Divider()
                    if !soundscape.description.isEmpty {
                        Text(soundscape.description)
                            .font(.body)
                            .lineSpacing(5)
                    }
                    SoundscapeSectionHeader(title: loc(.playerRecordingDetails), detail: soundscape.categoryDisplay)
                    Label(soundscape.locationDisplay, systemImage: "location")
                    Label(durationText, systemImage: "waveform")
                    if player.source == .madeForYou {
                        Divider()
                        SoundscapeSectionHeader(
                            title: loc(.playerFeedbackTitle),
                            detail: loc(.playerFeedbackDetail)
                        )
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) { feedbackButtons }
                            VStack(spacing: 10) { feedbackButtons }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SoundscapeTheme.screenPadding)
            }
            .soundscapeScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc(.generalDone)) { showsDetails = false }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder private var feedbackButtons: some View {
        Button(loc(.playerResonates)) {
            player.recordResonanceFeedback(ResonanceFeedback(kind: .resonated, listenedSeconds: player.elapsedSeconds))
        }
        .buttonStyle(SecondaryActionStyle())
        .accessibilityIdentifier("recommendation-resonates")

        Button(loc(.playerNotNow)) {
            showsDetails = false
            Task { await player.skipCurrent(reason: .notNow) }
        }
        .buttonStyle(SecondaryActionStyle())
        .accessibilityIdentifier("recommendation-not-now")

        Button(loc(.playerLessLikeThis), role: .destructive) {
            showsDetails = false
            Task { await player.skipCurrent(reason: .dislike) }
        }
        .buttonStyle(SecondaryActionStyle())
        .accessibilityIdentifier("recommendation-less-like-this")
    }

    private var durationText: String {
        let seconds = max(0, soundscape.durationSeconds)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
