import XCTest
@testable import Soundscape

final class ThemeContractTests: XCTestCase {
    private let themeJSON = #"{"id":9,"title":"City cycling","description":"Along the route","kind":"topic","starts_on":null,"ends_on":null,"recording_count":2}"#

    func testThemeAndRecordingEndpointsCarryViewerIdentity() async throws {
        let transport = StubHTTPTransport(stubs: [
            .init(data: Data("[\(themeJSON)]".utf8), status: 200),
            .init(data: Data("[{\"id\":11,\"title\":\"Bells\",\"theme\":\(themeJSON)}]".utf8), status: 200)
        ])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "viewer"))
        let repository = RemoteSoundscapeRepository(environment: .production, client: client)
        let themes = try await repository.themes()
        let recordings = try await repository.recordings(themeID: 9)
        XCTAssertEqual(themes[0].title, "City cycling")
        XCTAssertEqual(recordings[0].theme?.id, 9)
        let requests = await transport.requests
        XCTAssertEqual(requests.map { $0.url?.lastPathComponent }, ["themes", "soundscapes"])
        XCTAssertEqual(requests[1].url?.path, "/soundscape/api/themes/9/soundscapes")
        XCTAssertTrue(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer viewer" })
    }

    func testModeratorCreationUsesAuthenticatedThemeContract() async throws {
        let transport = StubHTTPTransport(stubs: [.init(data: Data(themeJSON.utf8), status: 200)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "moderator"))
        let repository = RemoteModerationRepository(environment: .production, client: client)
        _ = try await repository.createTheme(ListeningThemeDraft(title: "City cycling", description: "Along the route", kind: .topic, startsOn: nil, endsOn: nil))
        let requests = await transport.requests
        XCTAssertEqual(requests[0].url?.path, "/soundscape/api/moderation/themes")
        XCTAssertEqual(requests[0].httpMethod, "POST")
        XCTAssertEqual(requests[0].value(forHTTPHeaderField: "Authorization"), "Bearer moderator")
    }

    func testThemedUploadDoesNotChangePublicationIntent() async throws {
        let transport = StubHTTPTransport(stubs: [.init(data: Data(#"{"id":11,"is_public":0,"moderation_status":"pending"}"#.utf8), status: 200)])
        let repository = RemoteSoundscapeRepository(environment: .production,
            client: APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "creator")))
        let result = try await repository.create(CreateSoundscapeDraft(audio: MediaFile(data: Data([1]), filename: "test.m4a", contentType: "audio/mp4"), cover: nil, title: "Bells", description: "", latitude: nil, longitude: nil, locationName: "", category: "nature", promptText: "", personalSocial: 0.5, memoryPresent: 0.5, isPublic: false, themeID: 9))
        let requests = await transport.requests
        let body = String(decoding: try XCTUnwrap(requests[0].httpBody), as: UTF8.self)
        XCTAssertTrue(body.contains("name=\"theme_id\"\r\n\r\n9"))
        XCTAssertTrue(body.contains("name=\"is_public\"\r\n\r\n0"))
        XCTAssertEqual(result.moderationStatus, "pending")
        XCTAssertFalse(result.isPublic)
    }
}
