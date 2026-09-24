import Foundation

actor RemoteModerationRepository: ModerationRepository {
    private let environment: APIEnvironment
    private let client: APIClient
    init(environment: APIEnvironment, client: APIClient) {
        self.environment = environment
        self.client = client
    }

    func report(soundscapeID: Int, reason: String) async throws {
        struct Request: Encodable, Sendable { let reason: String }
        let _: Success = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.report(soundscapeID).value,
            method: "POST", body: Request(reason: reason)
        )
    }

    func block(creatorID: String) async throws {
        guard !creatorID.isEmpty, creatorID.range(of: "^[a-zA-Z0-9_-]{1,128}$", options: .regularExpression) != nil else {
            throw AppError.invalidRequest(loc(.errorInvalidParams))
        }
        let _: Success = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.blockCreator(creatorID).value,
            method: "POST", authenticated: true
        )
    }

    func hasModeratorAccess() async throws -> Bool {
        struct Access: Decodable, Sendable { let moderator: Bool }
        do {
            let response: Access = try await client.request(
                baseURL: environment.soundscapeAPIBaseURL,
                path: SoundscapeAPIPath.moderatorAccess.value,
                authenticated: true
            )
            return response.moderator
        } catch AppError.server(status: 403, code: _, message: _) {
            return false
        }
    }

    func pending() async throws -> [Soundscape] {
        let rows: [SoundscapeDTO] = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.pendingModeration.value,
            authenticated: true
        )
        return rows.map { $0.domain(environment: environment) }
    }

    func reports() async throws -> [ModerationReport] {
        try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.moderationReports.value,
            authenticated: true
        )
    }

    func previewAudio(soundscapeID: Int) async throws -> Data {
        try await client.download(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.moderatorAudio(soundscapeID).value
        )
    }

    func previewCover(soundscapeID: Int) async throws -> Data {
        try await client.download(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.moderatorCover(soundscapeID).value,
            maximumBytes: MediaConstraints.maximumCoverBytes
        )
    }

    func resolveReport(id: Int) async throws {
        let _: Success = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.resolveReport(id).value,
            method: "POST", authenticated: true
        )
    }

    func suspendCreator(id: String) async throws {
        guard !id.isEmpty, id.range(of: "^[a-zA-Z0-9_-]{1,128}$", options: .regularExpression) != nil else {
            throw AppError.invalidRequest(loc(.errorInvalidParams))
        }
        let _: Success = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.suspendCreator(id).value,
            method: "POST", authenticated: true
        )
    }

    func decide(soundscapeID: Int, action: ModerationDecision) async throws {
        let _: Success = try await client.request(
            baseURL: environment.soundscapeAPIBaseURL,
            path: SoundscapeAPIPath.moderationDecision(soundscapeID, action.rawValue).value,
            method: "POST", authenticated: true
        )
    }
}

private struct Success: Decodable, Sendable { let ok: Bool }
