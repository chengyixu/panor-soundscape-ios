import Observation

@MainActor
@Observable
final class LibraryViewModel {
    private(set) var state: LoadState<[Soundscape]> = .idle
    private(set) var favoriteState: LoadState<[Soundscape]> = .idle
    private(set) var mutationError: AppError?
    private let repository: any SoundscapeRepository
    private var loadGeneration = 0

    init(repository: any SoundscapeRepository) { self.repository = repository }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        state = .loading
        favoriteState = .loading
        async let recordings = loadRecordings()
        async let favorites = loadFavorites()
        let (recordingResult, favoriteResult) = await (recordings, favorites)
        guard generation == loadGeneration else { return }
        state = recordingResult.loadState
        favoriteState = favoriteResult.loadState
    }

    func reloadFavorites() async {
        favoriteState = .loading
        favoriteState = await loadFavorites().loadState
    }

    private func loadRecordings() async -> Result<[Soundscape], AppError> {
        do {
            return .success(try await repository.mine())
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.transport(String(describing: type(of: error))))
        }
    }

    private func loadFavorites() async -> Result<[Soundscape], AppError> {
        do {
            return .success(try await repository.saved())
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.transport(String(describing: type(of: error))))
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

private extension Result where Success == [Soundscape], Failure == AppError {
    var loadState: LoadState<[Soundscape]> {
        switch self {
        case .success(let items): .loaded(items)
        case .failure(let error): .failed(error)
        }
    }
}
