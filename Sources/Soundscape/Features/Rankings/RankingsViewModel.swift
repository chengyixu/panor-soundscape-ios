import Observation

@MainActor
@Observable
final class RankingsViewModel {
    private(set) var state: LoadState<[RankingLane]> = .idle
    private let repository: any SoundscapeRepository

    init(repository: any SoundscapeRepository) { self.repository = repository }

    func load(forceRefresh: Bool = false) async {
        state = .loading
        do {
            state = .loaded(try await repository.rankings(
                policy: forceRefresh ? .reloadIgnoringCache : .cacheFirst
            ))
        }
        catch let error as AppError { state = .failed(error) }
        catch { state = .failed(.transport(String(describing: type(of: error)))) }
    }
}
