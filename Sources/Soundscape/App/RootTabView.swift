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
    @State private var selection: AppShellTab = .explore
    @State private var hasHandledForYouLaunch = false
    @State private var hasNavigatedSinceLaunch = false
    @State private var automaticLaunchError: AppError?
    @State private var savedSyncError: AppError?
    @State private var isLaunchingPlayer = true
    @State private var vinylDragOffset = CGSize.zero
    @State private var vinylDragStartOffset: CGSize?
    @State private var navigationStartedOnNeedle: Bool?

    var body: some View {
        let locale = localeManager.current

        GeometryReader { proxy in
            let playerPresented = container.player.presentedSoundscape != nil

            ZStack {
                tabShell(bottomInset: proxy.safeAreaInsets.bottom)
                    .opacity(playerPresented ? 0 : 1)
                    .allowsHitTesting(!playerPresented)
                    .accessibilityHidden(playerPresented)
                    .simultaneousGesture(screenTransitionGesture(
                        size: proxy.size,
                        safeAreaTop: proxy.safeAreaInsets.top,
                        safeAreaBottom: proxy.safeAreaInsets.bottom
                    ))

                if let soundscape = container.player.presentedSoundscape ?? container.player.current {
                    TurntablePlayerView(
                        soundscape: soundscape,
                        player: container.player
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(playerPresented ? 1 : 0)
                    .allowsHitTesting(playerPresented)
                    .accessibilityHidden(!playerPresented)
                    .simultaneousGesture(screenTransitionGesture(
                        size: proxy.size,
                        safeAreaTop: proxy.safeAreaInsets.top,
                        safeAreaBottom: proxy.safeAreaInsets.bottom
                    ))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .animation(screenTransitionAnimation, value: playerPresented)
            .overlay {
                if isLaunchingPlayer && !playerPresented {
                    ZStack {
                        SoundscapeTheme.playerBackground.ignoresSafeArea()
                        VStack(spacing: 24) {
                            VinylRecordArtwork(isRotating: false)
                                .frame(width: 240, height: 240)
                            Text(loc(.playerLoading)).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if VinylIndicatorPresentation.shouldShow(
                    hasCurrentSoundscape: container.player.current != nil,
                    isPlayerPresented: playerPresented
                ) {
                    let vinylOffset = VinylIndicatorLayout.clampedOffset(
                        vinylDragOffset,
                        in: proxy.size,
                        safeAreaTop: proxy.safeAreaInsets.top,
                        safeAreaBottom: proxy.safeAreaInsets.bottom
                    )

                    VinylIndicatorButton(player: container.player)
                        .padding(.trailing, VinylIndicatorLayout.horizontalMargin)
                        .padding(.bottom, VinylIndicatorLayout.bottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
                        .offset(vinylOffset)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        .highPriorityGesture(
                            vinylDragGesture(
                                in: proxy.size,
                                safeAreaTop: proxy.safeAreaInsets.top,
                                safeAreaBottom: proxy.safeAreaInsets.bottom
                            )
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.86, anchor: .center)))
                }
            }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
        .preferredColorScheme(container.player.presentedSoundscape == nil ? .light : .dark)
        .task { await handleAutomaticLaunch() }
        .task(id: container.session.user?.id) {
            guard container.session.user != nil else {
                container.player.clearSavedSoundscapes()
                return
            }
            do {
                _ = try await container.player.refreshSavedSoundscapes()
            } catch let error as AppError {
                savedSyncError = error
            } catch {
                savedSyncError = .transport(String(describing: type(of: error)))
            }
        }
        .onChange(of: selection) { previous, current in
            if previous != current { hasNavigatedSinceLaunch = true }
        }
        .onChange(of: container.player.presentedSoundscape != nil) { _, _ in
            vinylDragStartOffset = nil
        }
        .alert(loc(.forYouCannotAutoPlay), isPresented: automaticLaunchErrorBinding) {
            Button(loc(.generalOK)) { automaticLaunchError = nil }
        } message: {
            Text(automaticLaunchError?.userMessage ?? loc(.errorTryAgain))
        }
        .alert(loc(.librarySaved), isPresented: Binding(
            get: { savedSyncError != nil },
            set: { if !$0 { savedSyncError = nil } }
        )) {
            Button(loc(.generalOK)) { savedSyncError = nil }
        } message: {
            Text(savedSyncError?.userMessage ?? loc(.errorTryAgain))
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
                    intentParser: container.intentParser,
                    isActive: selection == .me
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

    private func screenTransitionGesture(
        size: CGSize,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { _ in
                if navigationStartedOnNeedle == nil {
                    navigationStartedOnNeedle = container.player.isBrowsing
                }
            }
            .onEnded { value in
                let wasNeedleDrag = navigationStartedOnNeedle == true
                navigationStartedOnNeedle = nil
                guard !wasNeedleDrag else { return }
                guard container.player.current != nil else { return }
                let playerPresented = container.player.presentedSoundscape != nil
                if !playerPresented,
                   VinylIndicatorLayout.hitFrame(
                    offset: vinylDragOffset,
                    in: size,
                    safeAreaTop: safeAreaTop,
                    safeAreaBottom: safeAreaBottom
                   ).contains(value.startLocation) {
                    return
                }

                if playerPresented, TurntableNavigationGesture.shouldDismissPlayer(
                    translation: value.translation,
                    startX: value.startLocation.x,
                    width: size.width
                ) {
                    container.player.dismissPlayer(stopPlayback: false)
                } else if !playerPresented, TurntableNavigationGesture.shouldPresentPlayer(
                    translation: value.translation,
                    startX: value.startLocation.x,
                    width: size.width,
                    requiresLeadingEdge: selection == .map
                ) {
                    container.player.presentCurrentPlayer()
                }
            }
    }

    private func vinylDragGesture(
        in size: CGSize,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let startOffset = vinylDragStartOffset ?? vinylDragOffset
                let nextOffset = clampedVinylOffset(
                    startOffset: startOffset,
                    translation: value.translation,
                    in: size,
                    safeAreaTop: safeAreaTop,
                    safeAreaBottom: safeAreaBottom
                )

                withoutAnimation {
                    if vinylDragStartOffset == nil {
                        vinylDragStartOffset = startOffset
                    }
                    vinylDragOffset = nextOffset
                }
            }
            .onEnded { value in
                let intentionalDrag = VinylIndicatorInteraction.isIntentionalDrag(value.translation)
                let startOffset = vinylDragStartOffset ?? vinylDragOffset
                let finalOffset = clampedVinylOffset(
                    startOffset: startOffset,
                    translation: value.translation,
                    in: size,
                    safeAreaTop: safeAreaTop,
                    safeAreaBottom: safeAreaBottom
                )

                withoutAnimation {
                    if intentionalDrag { vinylDragOffset = finalOffset }
                    vinylDragStartOffset = nil
                }
                if !intentionalDrag { restorePlayer() }
            }
    }

    private func clampedVinylOffset(
        startOffset: CGSize,
        translation: CGSize,
        in size: CGSize,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGSize {
        VinylIndicatorLayout.clampedOffset(
            CGSize(
                width: startOffset.width + translation.width,
                height: startOffset.height + translation.height
            ),
            in: size,
            safeAreaTop: safeAreaTop,
            safeAreaBottom: safeAreaBottom
        )
    }

    private func withoutAnimation(_ update: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction, update)
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
        defer { isLaunchingPlayer = false }
        // UI tests for the other tabs deliberately start at the app shell.
#if DEBUG
        let forceFirstUse = ProcessInfo.processInfo.environment["SOUNDSCAPE_FORCE_FIRST_USE"] == "1"
        if forceFirstUse { return }
        if ProcessInfo.processInfo.environment["SOUNDSCAPE_UI_TEST_AUTOPLAY"] == "1" {
            guard let url = Bundle.main.url(forResource: "AutoplayTestTone", withExtension: "m4a") else {
                automaticLaunchError = .invalidRequest(loc(.errorNoPlayableReady))
                return
            }
            let fixture = Soundscape(
                id: -1,
                ownerID: "ui-test",
                authorName: "Soundscape",
                title: loc(.playerAutoplayTestTone),
                description: "",
                audioURL: url,
                coverURL: nil,
                coverIsAI: false,
                latitude: nil,
                longitude: nil,
                locationName: "",
                category: "nature",
                promptText: "",
                personalSocial: 0.5,
                memoryPresent: 0.5,
                durationSeconds: 3,
                isPublic: true,
                playCount: 0,
                fullPlayCount: 0,
                saveCount: 0,
                createdAt: ""
            )
            await container.player.openPlayer(fixture, sequence: [fixture], source: .direct)
            return
        }
#endif
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
