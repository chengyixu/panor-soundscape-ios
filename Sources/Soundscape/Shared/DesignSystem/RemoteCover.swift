import SwiftUI

struct RemoteCover: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    let url: URL?
    let category: String
    var isAI = false
    let avatarSeed: Int

    var body: some View {
        let locale = localeManager.current

        Group {
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: reduceMotion ? nil : .easeOut(duration: 0.25))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .overlay(alignment: .bottom) { aiDisclosure }
                    case .failure:
                        designedFallback
                    case .empty:
                        loadingCover
                    @unknown default:
                        designedFallback
                    }
                }
            } else {
                designedFallback
            }
        }
        .clipped()
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    @ViewBuilder private var aiDisclosure: some View {
        if isAI {
            ZStack {
                Rectangle().fill(.black)
                Text(loc(.coverAIBadge))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .accessibilityLabel(loc(.coverAILabel))
        }
    }

    private var loadingCover: some View {
        ZStack {
            SoundscapeTheme.paperDeep
            ProgressView().tint(SoundscapeTheme.ink)
        }
        .accessibilityLabel(loc(.coverLoading))
    }

    private var designedFallback: some View {
        GeometryReader { geometry in
            ZStack {
                SoundscapeTheme.paperDeep
                SoundscapeAvatar(seed: "soundscape:\(avatarSeed)", size: max(geometry.size.width, geometry.size.height))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .accessibilityLabel(loc(.coverDesignedArtwork))
        .accessibilityIdentifier("soundscape-artwork-\(avatarSeed)")
    }
}
