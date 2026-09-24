import Foundation
import XCTest
@testable import Soundscape

final class ModerationAPIContractTests: XCTestCase {
    func testReportIsAvailableWithoutAccountAndBlockRequiresAuthentication() async throws {
        let transport = StubHTTPTransport(stubs: [
            .init(data: Data(#"{"ok":true,"report_id":17}"#.utf8), status: 200),
            .init(data: Data(#"{"ok":true}"#.utf8), status: 200)
        ])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "private-session"))
        let moderation = RemoteModerationRepository(environment: .production, client: client)
        try await moderation.report(soundscapeID: 17, reason: "Harassment")
        try await moderation.block(creatorID: "u-abusive")
        let requests = await transport.requests
        XCTAssertEqual(requests.map { $0.url?.path }, ["/soundscape/api/soundscapes/17/report", "/soundscape/api/users/u-abusive/block"])
        XCTAssertNil(requests[0].value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "Authorization"), "Bearer private-session")
    }

    func testCreatorSuspensionUsesAuthenticatedModeratorEndpoint() async throws {
        let transport = StubHTTPTransport(stubs: [.init(data: Data(#"{"ok":true}"#.utf8), status: 200)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "moderator-session"))
        let moderation = RemoteModerationRepository(environment: .production, client: client)
        try await moderation.suspendCreator(id: "u-abusive")
        let requests = await transport.requests
        XCTAssertEqual(requests.first?.url?.path, "/soundscape/api/moderation/users/u-abusive/suspend")
        XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer moderator-session")
    }

    func testModeratorCanPreviewUnpublishedCoverWithAuthenticatedRequest() async throws {
        let bytes = Data([0x89, 0x50, 0x4e, 0x47])
        let transport = StubHTTPTransport(stubs: [.init(data: bytes, status: 200)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "moderator-session"))
        let moderation = RemoteModerationRepository(environment: .production, client: client)
        let preview = try await moderation.previewCover(soundscapeID: 9)
        XCTAssertEqual(preview, bytes)
        let requests = await transport.requests
        XCTAssertEqual(requests.first?.url?.path, "/soundscape/api/moderation/soundscapes/9/media/cover")
        XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer moderator-session")
    }

    func testPublicFeedSendsViewerTokenWhenAvailableToApplyBlocks() async throws {
        let transport = StubHTTPTransport(stubs: [.init(data: Data("[]".utf8), status: 200)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "viewer-session"))
        let repository = RemoteSoundscapeRepository(environment: .production, client: client)
        _ = try await repository.explore(category: nil, policy: .reloadIgnoringCache)
        let requests = await transport.requests
        XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer viewer-session")
    }

    func testModeratorQueueAndDecisionUseAuthenticatedBackendRole() async throws {
        let transport = StubHTTPTransport(stubs: [
            .init(data: Data(#"{"moderator":true}"#.utf8), status: 200),
            .init(data: Data("[]".utf8), status: 200),
            .init(data: Data(#"{"ok":true,"moderation_status":"approved"}"#.utf8), status: 200)
        ])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "private-session"))
        let moderation = RemoteModerationRepository(environment: .production, client: client)
        let access = try await moderation.hasModeratorAccess()
        let pending = try await moderation.pending()
        XCTAssertTrue(access)
        XCTAssertTrue(pending.isEmpty)
        try await moderation.decide(soundscapeID: 9, action: .approve)
        let requests = await transport.requests
        XCTAssertEqual(requests.map { $0.url?.path }, ["/soundscape/api/moderation/access", "/soundscape/api/moderation/pending", "/soundscape/api/moderation/soundscapes/9/approve"])
        XCTAssertTrue(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer private-session" })
    }
}
