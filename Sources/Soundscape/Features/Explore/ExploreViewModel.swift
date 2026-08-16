import Observation

@MainActor
@Observable
final class ExploreViewModel {
    private(set) var state: LoadState<[Soundscape]> = .idle
    var selectedCategory: String?
    private(set) var popularTerms: [String] = []

    private let repository: any SoundscapeRepository

    init(repository: any SoundscapeRepository) {
        self.repository = repository
    }

    func load(forceRefresh: Bool = false) async {
        state = .loading
        do {
            let items = try await repository.explore(
                category: selectedCategory,
                policy: forceRefresh ? .reloadIgnoringCache : .cacheFirst
            )
            state = .loaded(items)
            await loadPopularTerms(items: items, forceRefresh: forceRefresh)
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.transport(String(describing: type(of: error))))
        }
    }

    func select(category: String?) async {
        selectedCategory = category
        await load()
    }

    private func loadPopularTerms(items: [Soundscape], forceRefresh: Bool) async {
        do {
            let rankings = try await repository.rankings(policy: forceRefresh ? .reloadIgnoringCache : .cacheFirst)
            let rankedItems = rankings.flatMap(\.items)
            popularTerms = ExploreDiscovery.popularTerms(
                from: rankedItems.isEmpty ? items : rankedItems,
                limit: 10
            )
        } catch {
            popularTerms = ExploreDiscovery.popularTerms(from: items, limit: 10)
        }
    }
}
