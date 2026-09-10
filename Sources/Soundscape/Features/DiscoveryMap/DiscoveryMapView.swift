import MapKit
import SwiftUI

struct DiscoveryMapView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LocaleManager.self) private var localeManager
    @State private var model: DiscoveryMapViewModel
    @State private var position: MapCameraPosition = .automatic
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
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    Map(position: $position, selection: $model.selectedID) {
                        ForEach(items) { item in
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
                            showAll(items, animated: true)
                        } label: {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 38, height: 38)
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
                    .onChange(of: model.selectedID) {
                        focusSelection(in: items, animated: true)
                    }

                    if let selected = items.first(where: { $0.id == model.selectedID }) {
                        MapSelectionCard(soundscape: selected) {
                            Task { await player.openPlayer(selected, sequence: items, source: .map) }
                        }
                            .padding(14)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 14)
            }
            .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.82), value: model.selectedID)
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
    let play: () -> Void

    var body: some View {
        let locale = localeManager.current

        HStack(spacing: 14) {
            RemoteCover(url: soundscape.coverURL, category: soundscape.category, isAI: soundscape.coverIsAI)
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
                Text("\(soundscape.authorDisplay) · \(soundscape.categoryDisplay)")
                    .font(.caption)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                    .lineLimit(1)
                Text("\(soundscape.locationDisplay) · \(soundscape.durationDisplay)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: play) {
                Image(systemName: "play")
            }
            .buttonStyle(CircularActionStyle(
                foreground: SoundscapeTheme.paperRaised,
                background: SoundscapeTheme.ink,
                size: 46
            ))
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
