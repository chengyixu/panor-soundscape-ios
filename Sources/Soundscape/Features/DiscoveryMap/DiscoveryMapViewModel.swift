import Observation

@MainActor
@Observable
final class DiscoveryMapViewModel {
    private(set) var state: LoadState<[Soundscape]> = .idle
    var selectedID: Int?
    private let repository: any SoundscapeRepository

    init(repository: any SoundscapeRepository) { self.repository = repository }

    func load(forceRefresh: Bool = false) async {
        let existingItems: [Soundscape]?
        if case .loaded(let items) = state {
            existingItems = items
        } else {
            existingItems = nil
            state = .loading
        }
        do {
            let items = try await repository.explore(
                category: nil,
                policy: forceRefresh ? .reloadIgnoringCache : .cacheFirst
            ).filter(\.hasCoordinate)
            if selectedID == nil || !items.contains(where: { $0.id == selectedID }) {
                selectedID = items.first?.id
            }
            state = .loaded(items)
        } catch let error as AppError {
            state = existingItems.map(LoadState.loaded) ?? .failed(error)
        } catch {
            state = existingItems.map(LoadState.loaded)
                ?? .failed(.transport(String(describing: type(of: error))))
        }
    }
}
