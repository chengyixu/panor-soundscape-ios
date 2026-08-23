import Observation

@MainActor
@Observable
final class LibraryViewModel {
    private(set) var state: LoadState<[Soundscape]> = .idle
    private(set) var mutationError: AppError?
    private let repository: any SoundscapeRepository
    private var loadGeneration = 0

    init(repository: any SoundscapeRepository) { self.repository = repository }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        state = .loading
        do {
            let items = try await repository.mine()
            guard generation == loadGeneration else { return }
            state = .loaded(items)
        } catch let error as AppError {
            guard generation == loadGeneration else { return }
            state = .failed(error)
        } catch {
            guard generation == loadGeneration else { return }
            state = .failed(.transport(String(describing: type(of: error))))
        }
    }

    func toggleVisibility(_ item: Soundscape) async {
        do {
            try await repository.setVisibility(id: item.id, isPublic: !item.isPublic)
            mutationError = nil
            await load()
        } catch let error as AppError {
            mutationError = error
        } catch {
            mutationError = .transport(String(describing: type(of: error)))
        }
    }

    func delete(_ item: Soundscape) async {
        do {
            try await repository.delete(id: item.id)
            mutationError = nil
            await load()
        } catch let error as AppError {
            mutationError = error
        } catch {
            mutationError = .transport(String(describing: type(of: error)))
        }
    }
}

