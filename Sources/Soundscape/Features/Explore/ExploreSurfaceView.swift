import SwiftUI

struct ExploreSurfaceView: View {
    @Environment(LocaleManager.self) private var localeManager
    let repository: any SoundscapeRepository
    let player: AudioPlayerController
    @State private var mode: ExploreSurfaceMode = .discover

    var body: some View {
        let locale = localeManager.current

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ExploreSurfaceMode.allCases, id: \.self) { mode in
                    Button {
                        self.mode = mode
                    } label: {
                        VStack(spacing: 9) {
                            Text(mode.title(for: locale))
                                .font(.subheadline.weight(self.mode == mode ? .semibold : .regular))
                                .foregroundStyle(self.mode == mode ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                            Rectangle()
                                .fill(self.mode == mode ? SoundscapeTheme.ink : .clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("explore-mode-\(mode.rawValue)")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SoundscapeTheme.screenPadding)
            .padding(.top, 12)
            .overlay(alignment: .bottom) {
                Rectangle().fill(SoundscapeTheme.line.opacity(0.7)).frame(height: 0.75)
                    .padding(.horizontal, SoundscapeTheme.screenPadding)
            }

            switch mode {
            case .discover:
                ExploreView(repository: repository, player: player)
            case .rankings:
                RankingsView(repository: repository, player: player)
            }
        }
        .soundscapeScreenBackground()
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}
