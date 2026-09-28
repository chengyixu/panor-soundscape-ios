import MapKit
import SwiftUI

struct DiscoveryMapView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    @State private var model: DiscoveryMapViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var favoriteError: AppError?
    @State private var showsList = false
    @FocusState private var searchFocused: Bool
    let player: AudioPlayerController
    let isActive: Bool

    init(repository: any SoundscapeRepository, player: AudioPlayerController, isActive: Bool) {
        _model = State(initialValue: DiscoveryMapViewModel(repository: repository))
        self.player = player
        self.isActive = isActive
    }

    var body: some View {
        let locale = localeManager.current

        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: loc(.mapTitle))
                    .padding(.horizontal, SoundscapeTheme.screenPadding)
                    .padding(.top, SoundscapeTheme.screenPadding)
                searchControls
                    .padding(.horizontal, SoundscapeTheme.screenPadding)
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .soundscapeScreenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .task(id: isActive) {
                guard isActive else { return }
                await model.load(forceRefresh: true)
                if case .loaded(let items) = model.state {
                    showAll(items, animated: false)
                }
            }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
        .alert(loc(.librarySaved), isPresented: Binding(
            get: { favoriteError != nil },
            set: { if !$0 { favoriteError = nil } }
        )) {
            Button(loc(.generalOK)) { favoriteError = nil }
        } message: {
            Text(favoriteError?.userMessage ?? loc(.errorTryAgain))
        }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle, .loading:
            SoundscapeLoadingState(title: loc(.mapLoading))
                .frame(maxHeight: .infinity, alignment: .top)
        case .failed(let error):
            ErrorStateView(error: error) { Task { await model.load(forceRefresh: true) } }.padding(18)
        case .loaded(let items) where items.isEmpty:
            EmptyStateView(title: loc(.mapEmptyTitle), detail: loc(.mapEmpty), systemImage: "map").padding(18)
        case .loaded(let items):
            let results = model.results
            if showsList {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if results.isEmpty { Text(loc(.mapNoResults)).foregroundStyle(SoundscapeTheme.secondaryInk) }
                        ForEach(results) { item in
                            MapSelectionCard(soundscape: item,
                                isSaved: player.savedSoundscapeIDs.contains(item.id),
                                play: { Task { await player.openPlayer(item, sequence: results, source: .map) } },
                                favorite: { toggleFavorite(item) })
                                .onTapGesture { model.selectedID = item.id; showsList = false; focusSelection(in: results, animated: true) }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            } else {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    Map(position: $position, selection: $model.selectedID) {
                        ForEach(results) { item in
                            if let latitude = item.latitude, let longitude = item.longitude {
                                Annotation(item.displayTitle, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                                    let selected = model.selectedID == item.id
                                    ZStack {
                                        Circle()
                                            .fill(selected ? SoundscapeTheme.ink : SoundscapeTheme.paperRaised)
                                            .frame(width: selected ? 42 : 36, height: selected ? 42 : 36)
                                        Circle()
                                            .fill(selected ? SoundscapeTheme.paperRaised : SoundscapeTheme.ink)
                                            .frame(width: selected ? 10 : 8, height: selected ? 10 : 8)
                                    }
                                    .overlay { Circle().stroke(SoundscapeTheme.ink, lineWidth: 1) }
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("\(loc(.mapRecording)) \(item.displayTitle)")
                                    .accessibilityIdentifier("map-marker-\(item.id)")
                                    .animation(
                                        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.78),
                                        value: selected
                                    )
                                }
                                .tag(item.id)
                            }
                        }
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        model.cameraArea = RecordingMapArea(latitude: context.region.center.latitude,
                            longitude: context.region.center.longitude,
                            latitudeDelta: context.region.span.latitudeDelta,
                            longitudeDelta: context.region.span.longitudeDelta)
                    }
                    .mapStyle(
                        .standard(
                            elevation: .flat,
                            emphasis: .muted,
                            pointsOfInterest: .excludingAll,
                            showsTraffic: false
                        )
                    )
                    .saturation(0)
                    .contrast(1.08)
                    .frame(height: DiscoveryMapLayout.mapHeight(availableHeight: proxy.size.height))
                    .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.compactRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: SoundscapeTheme.compactRadius, style: .continuous)
                            .stroke(SoundscapeTheme.ink.opacity(0.72), lineWidth: 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        Button {
                            model.query = ""
                            model.clearArea()
                            showAll(items, animated: true)
                        } label: {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .foregroundStyle(SoundscapeTheme.ink)
                                .background(SoundscapeTheme.paperRaised)
                                .clipShape(Circle())
                                .overlay { Circle().stroke(SoundscapeTheme.ink.opacity(0.72), lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(loc(.mapShowAll))
                        .accessibilityIdentifier("map-show-all")
                        .padding(12)
                    }
                    .overlay(alignment: .topLeading) {
                        Button(loc(.mapSearchArea)) { model.searchThisArea() }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(SoundscapeTheme.paperRaised, in: Capsule())
                            .disabled(model.cameraArea == nil)
                            .accessibilityIdentifier("map-search-area")
                            .padding(12)
                    }
                    if results.isEmpty {
                        Text(loc(.mapNoResults))
                            .font(.subheadline).padding(16)
                            .background(SoundscapeTheme.paperRaised, in: RoundedRectangle(cornerRadius: 12))
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                    if let selected = results.first(where: { $0.id == model.selectedID }) {
                        MapSelectionCard(
                            soundscape: selected,
                            isSaved: player.savedSoundscapeIDs.contains(selected.id),
                            play: { Task { await player.openPlayer(selected, sequence: results, source: .map) } },
                            favorite: { toggleFavorite(selected) }
                        )
                            .padding(14)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: DiscoveryMapLayout.mapHeight(availableHeight: proxy.size.height))
                .padding(.horizontal, 14)
            }
            .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.82), value: model.selectedID)
            }
        }
    }

    private var searchControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                TextField(loc(.mapSearchPlaceholder), text: $model.query)
                    .focused($searchFocused)
                    .onSubmit { searchFocused = false }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityIdentifier("map-search")
                if !model.query.isEmpty {
                    Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44) }
                        .accessibilityLabel(loc(.exploreClearSearch))
                }
            }
            .padding(.leading, 14).padding(.trailing, 6)
            .frame(minHeight: 48)
            .background(SoundscapeTheme.paperRaised, in: Capsule())
            .overlay { Capsule().stroke(SoundscapeTheme.line, lineWidth: 1) }
            .onChange(of: model.query) {
                model.clearArea()
                showAll(model.results, animated: true)
            }
            HStack {
                Text("\(model.results.count) \(loc(.mapResults))").font(.caption.monospacedDigit())
                if model.areaFilter != nil {
                    Button(loc(.mapClearArea)) { model.clearArea(); showAll(model.results, animated: true) }
                        .font(.caption).frame(minHeight: 44)
                }
                Spacer()
                Button { showsList.toggle() } label: {
                    Label(loc(showsList ? .mapMapView : .mapListView), systemImage: showsList ? "map" : "list.bullet")
                }
                .font(.caption.weight(.semibold)).frame(minHeight: 44)
                .accessibilityIdentifier("map-list-toggle")
            }
            .foregroundStyle(SoundscapeTheme.secondaryInk)
        }
    }

    private func toggleFavorite(_ soundscape: Soundscape) {
        Task {
            do {
                _ = try await player.toggleSaved(soundscape)
                favoriteError = nil
            } catch let error as AppError {
                favoriteError = error
            } catch {
                favoriteError = .transport(String(describing: type(of: error)))
            }
        }
    }

    private func focusSelection(in items: [Soundscape], animated: Bool) {
        guard let selected = items.first(where: { $0.id == model.selectedID }),
              let latitude = selected.latitude,
              let longitude = selected.longitude else { return }
        let update = {
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.24, longitudeDelta: 0.24)
            ))
        }
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.34), update)
        } else {
            update()
        }
    }

    private func showAll(_ items: [Soundscape], animated: Bool) {
        guard let region = DiscoveryMapViewport.overviewRegion(for: items) else { return }
        let update = { position = .region(region) }
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.34), update)
        } else {
            update()
        }
    }
}

private struct MapSelectionCard: View {
    @Environment(LocaleManager.self) private var localeManager
    let soundscape: Soundscape
    let isSaved: Bool
    let play: () -> Void
    let favorite: () -> Void

    var body: some View {
        let locale = localeManager.current

        HStack(spacing: 14) {
            RemoteCover(url: soundscape.coverURL, category: soundscape.category, isAI: soundscape.coverIsAI, avatarSeed: soundscape.id)
                .saturation(0)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 2).stroke(SoundscapeTheme.line, lineWidth: 0.75) }
            VStack(alignment: .leading, spacing: 4) {
                Text(loc(.mapSelectedRecording))
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                Text(soundscape.displayTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(SoundscapeTheme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    CreatorAvatar(creatorID: soundscape.ownerID, size: 20)
                    Text("\(soundscape.authorDisplay) · \(soundscape.categoryDisplay)")
                        .font(.caption)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                        .lineLimit(1)
                }
                Text("\(soundscape.locationDisplay) · \(soundscape.durationDisplay)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                    .lineLimit(1)
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: favorite) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                }
                .buttonStyle(CircularActionStyle(
                    foreground: SoundscapeTheme.ink,
                    background: SoundscapeTheme.paperDeep,
                    size: 40
                ))
                .accessibilityLabel(isSaved ? loc(.playerUnsave) : loc(.playerSave))
                .accessibilityIdentifier("map-favorite-\(soundscape.id)")

                Button(action: play) {
                    Image(systemName: "play")
                }
                .buttonStyle(CircularActionStyle(
                    foreground: SoundscapeTheme.paperRaised,
                    background: SoundscapeTheme.ink,
                    size: 40
                ))
            }
        }
        .padding(14)
        .background(SoundscapeTheme.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.compactRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SoundscapeTheme.compactRadius, style: .continuous)
                .stroke(SoundscapeTheme.ink.opacity(0.72), lineWidth: 1)
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}
