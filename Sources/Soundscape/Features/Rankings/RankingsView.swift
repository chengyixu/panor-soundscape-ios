import SwiftUI

struct RankingsView: View {
    @Environment(LocaleManager.self) private var localeManager
    @State private var model: RankingsViewModel
    let player: AudioPlayerController

    init(repository: any SoundscapeRepository, player: AudioPlayerController) {
        _model = State(initialValue: RankingsViewModel(repository: repository))
        self.player = player
    }

    var body: some View {
        let locale = localeManager.current

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    ScreenHeader(eyebrow: loc(.rankingsEyebrow), title: loc(.rankingsTitle), detail: loc(.rankingsDetail))
                    content
                }
                .padding(.horizontal, SoundscapeTheme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .soundscapeScreenBackground()
            .refreshable { await model.load(forceRefresh: true) }
            .task { if case .idle = model.state { await model.load() } }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, 80)
        case .failed(let error):
            ErrorStateView(error: error) { Task { await model.load(forceRefresh: true) } }
        case .loaded(let lanes) where lanes.isEmpty:
            EmptyStateView(title: loc(.rankingsStillForming), detail: loc(.rankingsPlayAndSaveHelp), systemImage: "chart.bar")
        case .loaded(let lanes):
            ForEach(lanes) { lane in
                VStack(alignment: .leading, spacing: 14) {
                    SoundscapeSectionHeader(
                        title: "\(lane.categoryDisplay)\(loc(.rankingsLaneSuffix))",
                        trailing: "\(lane.items.count) \(loc(.soundscapeUnit))"
                    )
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 18) {
                            ForEach(lane.items) { item in
                                CDCard(soundscape: item) {
                                    Task { await player.openPlayer(item, sequence: lane.items, source: .rankings) }
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.horizontal, 2, for: .scrollContent)
                    .scrollTargetBehavior(.viewAligned)
                }
            }
        }
    }
}

private struct CDCard: View {
    let soundscape: Soundscape
    let play: () -> Void

    var body: some View {
        Button(action: play) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle().fill(SoundscapeTheme.ink.opacity(0.94)).frame(width: 154, height: 154)
                    RemoteCover(url: soundscape.coverURL, category: soundscape.category, isAI: soundscape.coverIsAI)
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                    Circle().fill(SoundscapeTheme.paper).frame(width: 28, height: 28)
                    Circle().stroke(SoundscapeTheme.paperRaised.opacity(0.6), lineWidth: 1).frame(width: 50, height: 50)
                }
                Text(soundscape.displayTitle).font(.headline).foregroundStyle(SoundscapeTheme.ink).lineLimit(1)
                Label("\(soundscape.playCount)", systemImage: "play.fill")
                    .font(.caption.monospaced())
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            .frame(width: 160, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
