import Foundation

/// Coalesces concurrent feed requests without retaining UGC that may have been
/// blocked or removed after the last successful response.
actor CachedSoundscapeRepository: SoundscapeRepository {
    private let upstream: any SoundscapeRepository
    private var exploreTasks: [String: Task<[Soundscape], Error>] = [:]
    private var rankingsTask: Task<[RankingLane], Error>?

    init(upstream: any SoundscapeRepository) {
        self.upstream = upstream
    }

    func explore(category: String?, policy: RepositoryReadPolicy) async throws -> [Soundscape] {
        let key = category ?? ""
        if let task = exploreTasks[key] { return try await task.value }
        let task = Task { [upstream] in
            try await upstream.explore(category: category, policy: .reloadIgnoringCache)
        }
        exploreTasks[key] = task
        defer { exploreTasks[key] = nil }
        return try await task.value
    }

    func rankings(policy: RepositoryReadPolicy) async throws -> [RankingLane] {
        if let rankingsTask { return try await rankingsTask.value }
        let task = Task { [upstream] in
            try await upstream.rankings(policy: .reloadIgnoringCache)
        }
        rankingsTask = task
        defer { rankingsTask = nil }
        return try await task.value
    }

    func mine() async throws -> [Soundscape] { try await upstream.mine() }
    func saved() async throws -> [Soundscape] { try await upstream.saved() }
    func create(_ draft: CreateSoundscapeDraft) async throws -> Soundscape { try await upstream.create(draft) }
    func suggestTitle(_ request: TitleSuggestionRequest) async throws -> TitleSuggestion {
        try await upstream.suggestTitle(request)
    }
    func suggestCover(_ request: CoverSuggestionRequest) async throws -> CoverSuggestion {
        try await upstream.suggestCover(request)
    }
    func previewStagedCover(path: String) async throws -> Data {
        try await upstream.previewStagedCover(path: path)
    }
    func reportPlay(id: Int, listenedSeconds: Int) async throws -> PlayResponse {
        try await upstream.reportPlay(id: id, listenedSeconds: listenedSeconds)
    }
    func toggleSave(id: Int) async throws -> SaveResponse { try await upstream.toggleSave(id: id) }
    func setVisibility(id: Int, isPublic: Bool) async throws {
        try await upstream.setVisibility(id: id, isPublic: isPublic)
    }
    func delete(id: Int) async throws { try await upstream.delete(id: id) }
}
