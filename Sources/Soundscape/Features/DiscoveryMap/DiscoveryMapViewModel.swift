import Foundation
import Observation

@MainActor
@Observable
final class DiscoveryMapViewModel {
    private(set) var state: LoadState<[Soundscape]> = .idle
    var selectedID: Int?
    var query = "" { didSet { reconcileSelection() } }
    var cameraArea: RecordingMapArea?
    private(set) var areaFilter: RecordingMapArea?
    private let repository: any SoundscapeRepository
    private var generation = 0

    init(repository: any SoundscapeRepository) { self.repository = repository }

    var results: [Soundscape] {
        guard case .loaded(let items) = state else { return [] }
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return items.filter { item in
            let fields = [item.displayTitle, item.description, item.locationDisplay, item.authorDisplay, item.categoryDisplay, item.theme?.title ?? ""]
            guard words.allSatisfy({ word in fields.contains { $0.localizedStandardContains(word) } }) else { return false }
            if let areaFilter, let lat = item.latitude, let lon = item.longitude {
                return areaFilter.contains(latitude: lat, longitude: lon)
            }
            return true
        }
    }

    func searchThisArea() { areaFilter = cameraArea; reconcileSelection() }
    func clearArea() { areaFilter = nil; reconcileSelection() }

    func load(forceRefresh: Bool = false) async {
        generation += 1
        let request = generation
        state = .loading
        do {
            let items = try await repository.explore(category: nil,
                policy: forceRefresh ? .reloadIgnoringCache : .cacheFirst).filter(\.hasCoordinate)
            guard request == generation, !Task.isCancelled else { return }
            state = .loaded(items)
            reconcileSelection()
        } catch {
            guard request == generation else { return }
            selectedID = nil
            state = .failed((error as? AppError) ?? .transport(String(describing: type(of: error))))
        }
    }

    private func reconcileSelection() {
        let items = results
        if selectedID == nil || !items.contains(where: { $0.id == selectedID }) { selectedID = items.first?.id }
    }
}
