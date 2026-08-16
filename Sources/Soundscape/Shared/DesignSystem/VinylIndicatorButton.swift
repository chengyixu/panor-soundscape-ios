import SwiftUI

struct VinylRecordArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isRotating: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || !isRotating)) { context in
            let rotation = reduceMotion
                ? 0
                : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 13) / 13 * 360

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
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(player.current == nil)
        .opacity(player.current == nil ? 0.22 : 1.0)
        .accessibilityLabel(loc(.playerOpenPlayer))
        .accessibilityIdentifier("vinyl-player-indicator")
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}
