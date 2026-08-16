import Foundation

actor RemoteSoundscapeRepository: SoundscapeRepository {
    private let environment: APIEnvironment
    private let client: APIClient

    init(environment: APIEnvironment, client: APIClient) {
        self.environment = environment
        self.client = client
    }

    func explore(category: String?, policy: RepositoryReadPolicy) async throws -> [Soundscape] {
        var query = [URLQueryItem(name: "scope", value: "explore")]
        if let category, !category.isEmpty { query.append(URLQueryItem(name: "category", value: category)) }
        let rows: [SoundscapeDTO] = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.soundscapes.value,
            query: query
        )
        return rows.map { $0.domain(environment: environment) }
    }

    func rankings(policy: RepositoryReadPolicy) async throws -> [RankingLane] {
        let rows: [RankingLaneDTO] = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.rankings.value
        )
        return rows.map { lane in
            RankingLane(category: lane.category, items: lane.items.map { $0.domain(environment: environment) })
        }
    }

    func mine() async throws -> [Soundscape] {
        let rows: [SoundscapeDTO] = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.mySoundscapes.value,
            authenticated: true
        )
        return rows.map { $0.domain(environment: environment) }
    }

    func create(_ draft: CreateSoundscapeDraft) async throws -> Soundscape {
        var builder = MultipartBuilder()
        builder.addFile(name: "audio", file: draft.audio)
        switch draft.cover {
        case .upload(let file): builder.addFile(name: "cover", file: file)
        case .generated(let path): builder.addField(name: "cover_url", value: path)
        }
        builder.addField(name: "title", value: draft.title)
        builder.addField(name: "description", value: draft.description)
        if let latitude = draft.latitude { builder.addField(name: "lat", value: String(latitude)) }
        if let longitude = draft.longitude { builder.addField(name: "lng", value: String(longitude)) }
        builder.addField(name: "location_name", value: draft.locationName)
        builder.addField(name: "category", value: draft.category)
        builder.addField(name: "prompt_text", value: draft.promptText)
        builder.addField(name: "tag_personal_social", value: String(draft.personalSocial))
        builder.addField(name: "tag_memory_present", value: String(draft.memoryPresent))
        builder.addField(name: "is_public", value: draft.isPublic ? "1" : "0")
        let dto: SoundscapeDTO = try await client.upload(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.soundscapes.value,
            multipart: builder.build(),
            authenticated: true
        )
        return dto.domain(environment: environment)
    }

    func suggestTitle(_ request: TitleSuggestionRequest) async throws -> TitleSuggestion {
        try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.aiTitle.value,
            method: "POST",
            body: request,
            timeoutInterval: 60
        )
    }

    func suggestCover(_ request: CoverSuggestionRequest) async throws -> CoverSuggestion {
        try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.aiCover.value,
            method: "POST",
            body: request,
            timeoutInterval: 180
        )
    }

    func reportPlay(id: Int, listenedSeconds: Int) async throws -> PlayResponse {
        struct Request: Encodable, Sendable { let listened_sec: Int }
        return try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.play(id).value,
            method: "POST",
            body: Request(listened_sec: listenedSeconds)
        )
    }

    func toggleSave(id: Int) async throws -> SaveResponse {
        try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.save(id).value,
            method: "POST",
            body: EmptyBody(),
            authenticated: true
        )
    }

    func setVisibility(id: Int, isPublic: Bool) async throws {
        struct Request: Encodable, Sendable { let is_public: Int }
        let _: MutationResponse = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.visibility(id).value,
            method: "POST",
            body: Request(is_public: isPublic ? 1 : 0),
            authenticated: true
        )
    }

    func delete(id: Int) async throws {
        let _: MutationResponse = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.soundscape(id).value,
            method: "DELETE",
            authenticated: true
        )
    }
}

private struct EmptyBody: Encodable, Sendable {}
