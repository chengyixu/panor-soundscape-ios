import SwiftUI

enum AutomaticPlayerLaunchPolicy {
    static func shouldPresentRecommendation(
        hasNavigatedSinceLaunch: Bool,
        hasCurrentSoundscape: Bool,
        hasPresentedSoundscape: Bool
    ) -> Bool {
        !hasNavigatedSinceLaunch && !hasCurrentSoundscape && !hasPresentedSoundscape
    }
}

struct RootTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    let container: AppContainer
    @AppStorage("soundscape.for-you.has-opened") private var hasOpenedBefore = false
    @State private var selection: AppShellTab = .explore
    @State private var hasHandledForYouLaunch = false
    @State private var hasNavigatedSinceLaunch = false
    @State private var automaticLaunchError: AppError?

    var body: some View {
        let locale = localeManager.current

        GeometryReader { proxy in
            let playerPresented = container.player.presentedSoundscape != nil

            ZStack {
                tabShell(bottomInset: proxy.safeAreaInsets.bottom)
                    .opacity(playerPresented ? 0 : 1)
                    .allowsHitTesting(!playerPresented)
                    .accessibilityHidden(playerPresented)

                if let soundscape = container.player.presentedSoundscape ?? container.player.current {
                    TurntablePlayerView(
                        soundscape: soundscape,
                        player: container.player
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(playerPresented ? 1 : 0)
                    .allowsHitTesting(playerPresented)
                    .accessibilityHidden(!playerPresented)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .animation(screenTransitionAnimation, value: playerPresented)
            .simultaneousGesture(screenTransitionGesture(width: proxy.size.width))
            .overlay(alignment: Alignment.topTrailing) {
                if !playerPresented {
                    VinylIndicatorButton(player: container.player)
                        .padding(.trailing, 16)
                        .padding(.top, max(proxy.safeAreaInsets.top + 8, 16))
                        .transition(.opacity.combined(with: .scale(scale: 0.86, anchor: .center)))
                }
            }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
        .preferredColorScheme(container.player.presentedSoundscape == nil ? .light : .dark)
        .task { await handleAutomaticLaunch() }
        .onChange(of: selection) { previous, current in
            if previous != current { hasNavigatedSinceLaunch = true }
        }
        .alert(loc(.forYouCannotAutoPlay), isPresented: automaticLaunchErrorBinding) {
            Button(loc(.generalOK)) { automaticLaunchError = nil }
        } message: {
            Text(automaticLaunchError?.userMessage ?? loc(.errorTryAgain))
        }
    }

    private func tabShell(bottomInset: CGFloat) -> some View {
        ZStack {
            tabSurface(for: .explore) {
                ExploreSurfaceView(repository: container.soundscapes, player: container.player)
            }

            tabSurface(for: .map) {
                DiscoveryMapView(
                    repository: container.soundscapes,
                    player: container.player,
                    isActive: selection == .map
                )
            }

            tabSurface(for: .contribute) {
                CreateSoundscapeView(
                    repository: container.soundscapes,
                    recorder: container.recorder,
                    location: container.location,
                    session: container.session,
                    isActive: selection == .contribute
                )
            }

            tabSurface(for: .me) {
                LibraryView(
                    repository: container.soundscapes,
                    recorder: container.recorder,
                    session: container.session,
                    player: container.player,
                    matching: container.matching,
                    intentParser: container.intentParser
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SoundscapeTabBar(selection: $selection, bottomInset: bottomInset)
                .padding(.bottom, -bottomInset)
        }
    }

    private func tabSurface<Content: View>(
        for tab: AppShellTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .toolbar(.hidden, for: .navigationBar)
            .opacity(selection == tab ? 1 : 0)
            .allowsHitTesting(selection == tab)
            .accessibilityHidden(selection != tab)
            .zIndex(selection == tab ? 1 : 0)
    }

    private func screenTransitionGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard container.player.current != nil else { return }
                let playerPresented = container.player.presentedSoundscape != nil

                if playerPresented, TurntableNavigationGesture.shouldDismissPlayer(
                    translation: value.translation,
                    startX: value.startLocation.x,
                    width: width
                ) {
                    container.player.dismissPlayer(stopPlayback: false)
                } else if !playerPresented, TurntableNavigationGesture.shouldPresentPlayer(
                    translation: value.translation,
                    startX: value.startLocation.x,
                    width: width,
                    requiresLeadingEdge: selection == .map
                ) {
                    container.player.presentCurrentPlayer()
                }
            }
    }

    private var screenTransitionAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.26)
    }

    private func restorePlayer() {
        guard container.player.current != nil else { return }
        container.player.presentCurrentPlayer()
    }

    private func handleAutomaticLaunch() async {
        guard !hasHandledForYouLaunch else { return }
        hasHandledForYouLaunch = true

        let forceFirstUse = ProcessInfo.processInfo.environment["SOUNDSCAPE_FORCE_FIRST_USE"] == "1"
        if forceFirstUse || !hasOpenedBefore {
            hasOpenedBefore = true
            return
        }
        if container.player.current != nil {
            restorePlayer()
            return
        }

        do {
            let batch = try await container.matching.returningRecommendations()
            guard AutomaticPlayerLaunchPolicy.shouldPresentRecommendation(
                hasNavigatedSinceLaunch: hasNavigatedSinceLaunch,
                hasCurrentSoundscape: container.player.current != nil,
                hasPresentedSoundscape: container.player.presentedSoundscape != nil
            ) else { return }
            await container.player.openRecommendationBatch(batch)
        } catch let appError as AppError {
            automaticLaunchError = appError
        } catch {
            automaticLaunchError = .transport(String(describing: type(of: error)))
        }
    }

    private var automaticLaunchErrorBinding: Binding<Bool> {
        Binding(
            get: { automaticLaunchError != nil },
            set: { if !$0 { automaticLaunchError = nil } }
        )
    }
}

private struct SoundscapeTabBar: View {
    @Environment(LocaleManager.self) private var localeManager
    @Binding var selection: AppShellTab
    let bottomInset: CGFloat

    private var totalHeight: CGFloat { 56 + bottomInset }

    var body: some View {
        let locale = localeManager.current

        ZStack {
            Color.clear
                .accessibilityElement()
                .accessibilityLabel(SoundscapeLocale.generalPrimaryNavigation.localized(for: locale))
                .accessibilityIdentifier("primary-tab-bar")
                .allowsHitTesting(false)

            HStack(spacing: 0) {
                ForEach(AppShellTab.allCases, id: \.self) { tab in
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: selection == tab ? tab.selectedSystemImage : tab.systemImage)
                                .font(.system(size: 21, weight: .medium))
                                .frame(height: 24)
                            Text(tab.title(for: locale))
                                .font(.caption2.weight(selection == tab ? .semibold : .regular))
                        }
                        .foregroundStyle(SoundscapeTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: totalHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title(for: locale))
                    .accessibilityIdentifier("tab-\(tab.rawValue)")
                }
            }
        }
        .frame(height: totalHeight)
        .background(SoundscapeTheme.paperRaised)
        .overlay(alignment: .top) {
            Rectangle().fill(SoundscapeTheme.line.opacity(0.72)).frame(height: 0.75)
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}
