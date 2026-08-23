import XCTest
@testable import Soundscape

final class APIClientRetryTests: XCTestCase {
    private struct Item: Codable, Equatable, Sendable {
        let id: Int
    }

    private let baseURL = APIEnvironment.production.soundscapeAPIBaseURL
    private static let listResponse = Data(#"[{"id": 7}]"#.utf8)

    func testGetRetriesOnceOnTransientTransportFailure() async throws {
        let transport = StubHTTPTransport(stubs: [
            .failure(.transport("URLError.-1005")),
            .init(data: Self.listResponse, status: 200)
        ])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        let items: [Item] = try await client.request(baseURL: baseURL, path: SoundscapeAPIPath.health.value)

        XCTAssertEqual(items, [Item(id: 7)])
        let requests = await transport.requests
        XCTAssertEqual(requests.count, 2)
    }

    func testGetDoesNotRetryWhenTransportFailsTwice() async {
        let transport = StubHTTPTransport(stubs: [
            .failure(.transport("URLError.-1009")),
            .failure(.transport("URLError.-1009"))
        ])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        do {
            let _: [Item] = try await client.request(baseURL: baseURL, path: SoundscapeAPIPath.health.value)
            XCTFail("Expected transport failure after bounded retry")
        } catch let error as AppError {
            XCTAssertEqual(error, .transport("URLError.-1009"))
        } catch {
            XCTFail("Expected AppError")
        }
        let requests = await transport.requests
        XCTAssertEqual(requests.count, 2)
    }

    func testPostIsNotRetriedOnTransportFailure() async {
        let transport = StubHTTPTransport(stubs: [.failure(.transport("URLError.-1005"))])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore(token: "session-token"))

        do {
            let _: MutationResponse = try await client.request(
                baseURL: baseURL,
                path: SoundscapeAPIPath.save(3).value,
                method: "POST",
                body: EmptyRequestBody(),
                authenticated: true
            )
            XCTFail("Expected transport failure without retry")
        } catch let error as AppError {
            XCTAssertEqual(error, .transport("URLError.-1005"))
        } catch {
            XCTFail("Expected AppError")
        }
        let requests = await transport.requests
        XCTAssertEqual(requests.count, 1)
    }

    func testGetIsNotRetriedOnServerError() async {
        let transport = StubHTTPTransport(stubs: [.init(data: Data(#"{"detail":"boom"}"#.utf8), status: 500)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        do {
            let _: [Item] = try await client.request(baseURL: baseURL, path: SoundscapeAPIPath.health.value)
            XCTFail("Expected server failure without retry")
        } catch let error as AppError {
            XCTAssertEqual(error, .server(status: 500, code: nil, message: "boom"))
        } catch {
            XCTFail("Expected AppError")
        }
        let requests = await transport.requests
        XCTAssertEqual(requests.count, 1)
    }

    func testGetIsNotRetriedOnDecodingFailure() async {
        let transport = StubHTTPTransport(stubs: [.init(data: Data(#"{"not":"the-list"}"#.utf8), status: 200)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        do {
            let _: [Item] = try await client.request(baseURL: baseURL, path: SoundscapeAPIPath.health.value)
            XCTFail("Expected decoding failure without retry")
        } catch let error as AppError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Expected AppError")
        }
        let requests = await transport.requests
        XCTAssertEqual(requests.count, 1)
    }
}

private struct EmptyRequestBody: Encodable, Sendable {}
