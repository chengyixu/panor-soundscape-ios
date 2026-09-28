import Foundation
import Observation

/// One observable, account-keyed source for all creator portraits in this app.
/// The store is device-local; generated defaults are stable, not server profiles.
@MainActor
@Observable
final class CreatorAvatarResolver {
    private let store: any ProfileAvatarStore
    private var values: [String: ProfileAvatar] = [:]
    private var revisions: [String: Int] = [:]
    @ObservationIgnored private var loads: [String: Task<ProfileAvatar, Error>] = [:]
    private(set) var loadErrors: [String: AppError] = [:]

    init(store: any ProfileAvatarStore) { self.store = store }

    func cachedAvatar(for id: String) -> ProfileAvatar? { values[id] }

    func avatar(for id: String) -> ProfileAvatar {
        values[id] ?? .generated(ProfileAvatar.generatedIndex(for: id))
    }

    func load(for id: String) async throws {
        guard values[id] == nil, !id.isEmpty else { return }
        let revision = revisions[id, default: 0]
        let pending = loads[id] ?? Task { [store] in try await store.avatar(for: id) }
        loads[id] = pending
        defer { loads[id] = nil }
        do {
            let value = try await pending.value
            guard revisions[id, default: 0] == revision, values[id] == nil else { return }
            values[id] = value
            loadErrors[id] = nil
        } catch {
            guard revisions[id, default: 0] == revision else { return }
            loadErrors[id] = .invalidRequest(loc(.errorCannotProcessImage))
            throw error
        }
    }

    func resolve(for id: String) async {
        do { try await load(for: id) }
        catch { /* loadErrors retains the failure; keep the generated portrait. */ }
    }

    func save(photo: Data, for id: String) async throws {
        revisions[id, default: 0] += 1
        let revision = revisions[id, default: 0]
        try await store.save(photo: photo, for: id)
        guard revisions[id, default: 0] == revision else { return }
        values[id] = .photo(photo)
        loadErrors[id] = nil
    }
}
