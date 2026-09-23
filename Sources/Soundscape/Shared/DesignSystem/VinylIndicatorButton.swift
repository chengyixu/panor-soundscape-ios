import SwiftUI

enum VinylIndicatorPresentation {
    static func shouldShow(hasCurrentSoundscape: Bool, isPlayerPresented: Bool) -> Bool {
        hasCurrentSoundscape && !isPlayerPresented
    }
}

enum VinylIndicatorInteraction {
    static let minimumDragDistance: CGFloat = 14

    static func isIntentionalDrag(_ translation: CGSize) -> Bool {
        max(abs(translation.width), abs(translation.height)) >= minimumDragDistance
    }
}

enum VinylIndicatorLayout {
    static let diameter: CGFloat = 44
    static let horizontalMargin: CGFloat = 20
    static let topMargin: CGFloat = 16
    static let tabBarHeight: CGFloat = 56
    static let tabBarGap: CGFloat = 16

    static func bottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        safeAreaBottom + tabBarHeight + tabBarGap
    }

    static func baseCenter(in size: CGSize, safeAreaBottom: CGFloat) -> CGPoint {
        CGPoint(
            x: size.width - horizontalMargin - diameter / 2,
            y: size.height - bottomPadding(safeAreaBottom: safeAreaBottom) - diameter / 2
        )
    }

    static func clampedOffset(
        _ offset: CGSize,
        in size: CGSize,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGSize {
        let base = baseCenter(in: size, safeAreaBottom: safeAreaBottom)
        let minimumCenter = CGPoint(
            x: horizontalMargin + diameter / 2,
            y: safeAreaTop + topMargin + diameter / 2
        )
        let maximumCenter = CGPoint(
            x: max(minimumCenter.x, size.width - horizontalMargin - diameter / 2),
            y: max(
                minimumCenter.y,
                size.height - bottomPadding(safeAreaBottom: safeAreaBottom) - diameter / 2
            )
        )
        let center = CGPoint(
            x: min(maximumCenter.x, max(minimumCenter.x, base.x + offset.width)),
            y: min(maximumCenter.y, max(minimumCenter.y, base.y + offset.height))
        )
        return CGSize(width: center.x - base.x, height: center.y - base.y)
    }

    static func hitFrame(
        offset: CGSize,
        in size: CGSize,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGRect {
        let clamped = clampedOffset(
            offset,
            in: size,
            safeAreaTop: safeAreaTop,
            safeAreaBottom: safeAreaBottom
        )
        let base = baseCenter(in: size, safeAreaBottom: safeAreaBottom)
        return CGRect(
            x: base.x + clamped.width - diameter / 2,
            y: base.y + clamped.height - diameter / 2,
            width: diameter,
            height: diameter
        )
    }

}

struct VinylRecordArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isRotating: Bool
    var showsPlaybackGroove = false
    @State private var rotationStarted = Date()
    @State private var accumulatedRotation: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: reduceMotion || !isRotating)) { context in
            let rotation = reduceMotion
                ? 0
                : accumulatedRotation + (isRotating ? context.date.timeIntervalSince(rotationStarted) / 13 * 360 : 0)

            GeometryReader { proxy in
                let diameter = min(proxy.size.width, proxy.size.height)

                ZStack {
                    Circle()
                        .fill(Color(red: 0.018, green: 0.018, blue: 0.018))
                    Circle()
                        .stroke(.white.opacity(0.82), lineWidth: max(0.8, diameter * 0.0025))
                    ForEach(0..<18, id: \.self) { groove in
                        Circle()
                            .stroke(
                                .white.opacity(groove.isMultiple(of: 3) ? 0.09 : 0.045),
                                lineWidth: max(0.35, diameter * 0.0014)
                            )
                            .padding(diameter * (0.03 + CGFloat(groove) * 0.0215))
                    }
                    if showsPlaybackGroove {
                        Circle()
                            .stroke(.white.opacity(0.18), lineWidth: 0.6)
                            .padding(diameter * 0.13)
                        ForEach(0..<7, id: \.self) { segment in
                            Circle()
                                .trim(from: CGFloat(segment) / 7, to: CGFloat(segment) / 7 + 0.055)
                                .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                                .padding(diameter * 0.13)
                        }
                    }
                    Circle()
                        .fill(.white)
                        .frame(width: diameter * 0.27, height: diameter * 0.27)
                        .overlay {
                            Circle()
                                .fill(SoundscapeTheme.playerBackground)
                                .frame(width: diameter * 0.03, height: diameter * 0.03)
                        }
                }
                .frame(width: diameter, height: diameter)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .rotationEffect(.degrees(rotation))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup()
        .accessibilityHidden(true)
        .onChange(of: isRotating) { _, rotating in
            let now = Date()
            if !rotating {
                accumulatedRotation += now.timeIntervalSince(rotationStarted) / 13 * 360
                accumulatedRotation.formTruncatingRemainder(dividingBy: 360)
            }
            rotationStarted = now
        }
    }
}

struct VinylIndicatorButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    let player: AudioPlayerController

    init(player: AudioPlayerController) {
        self.player = player
    }

    var body: some View {
        let locale = localeManager.current

        Button {
            if player.current != nil {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.26)) {
                    player.presentCurrentPlayer()
                }
            }
        } label: {
            VinylRecordArtwork(isRotating: player.isPlaying)
                .frame(width: VinylIndicatorLayout.diameter, height: VinylIndicatorLayout.diameter)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .disabled(player.current == nil)
        .opacity(player.current == nil ? 0.22 : 1.0)
        .accessibilityLabel(loc(.playerOpenPlayer))
        .accessibilityHint(loc(.playerMoveIndicatorHint))
        .accessibilityIdentifier("vinyl-player-indicator")
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}
