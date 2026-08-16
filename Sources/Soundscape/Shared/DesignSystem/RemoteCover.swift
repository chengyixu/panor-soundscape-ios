import SwiftUI

struct RemoteCover: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    let url: URL?
    let category: String
    var isAI = false

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
                        unavailableCover(systemImage: "exclamationmark", label: loc(.coverLoadFailed))
                    case .empty:
                        loadingCover
                    @unknown default:
                        unavailableCover(systemImage: "exclamationmark", label: loc(.coverLoadFailed))
                    }
                }
            } else {
                unavailableCover(systemImage: "photo", label: loc(.coverNoCover))
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

    private func unavailableCover(systemImage: String, label: String) -> some View {
        ZStack {
            SoundscapeTheme.paperDeep
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(SoundscapeTheme.secondaryInk)
        }
        .accessibilityLabel(label)
    }
}
