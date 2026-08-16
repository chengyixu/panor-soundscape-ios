import Observation

@MainActor
@Observable
final class LibraryViewModel {
    private(set) var state: LoadState<[Soundscape]> = .idle
    private(set) var mutationError: AppError?
    private let repository: any SoundscapeRepository

    init(repository: any SoundscapeRepository) { self.repository = repository }

    func load() async {
        state = .loading
        do { state = .loaded(try await repository.mine()) }
        catch let error as AppError { state = .failed(error) }
        catch { state = .failed(.transport(String(describing: type(of: error)))) }
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

