import XCTest
@testable import Soundscape

final class APIClientContractTests: XCTestCase {
    func testLoginSendsUsernameOrEmailIdentifierAndStoresReturnedToken() async throws {
        let response = Data(#"{"success":true,"sessionId":"login-session","user":{"id":"u_7","name":"wilsonxu","email":"chengyi_xu@outlook.com","picture":null}}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: response, status: 200)])
        let tokenStore = InMemoryTokenStore()
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        let user = try await repository.login(credentials: LoginCredentials(identifier: "wilsonxu", password: "secret12"))

        XCTAssertEqual(user.username, "wilsonxu")
        let storedToken = try await tokenStore.token()
        XCTAssertEqual(storedToken, "login-session")
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://www.panor.tech/api/auth/login")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, ["identifier": "wilsonxu", "password": "secret12"])
    }

    func testRegistrationSendsRequiredEmailAndStoresReturnedToken() async throws {
        let response = Data(#"{"success":true,"sessionId":"registered-token","user":{"id":"u_72","name":"new-user","email":"new-user@example.com","picture":null}}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: response, status: 200)])
        let tokenStore = InMemoryTokenStore()
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        let user = try await repository.register(credentials: RegistrationCredentials(
            email: "new-user@example.com",
            password: "secret12",
            name: "new-user"
        ))

        XCTAssertEqual(user, PanorUser(
            id: "u_72",
            name: "new-user",
            email: "new-user@example.com",
            picture: nil
        ))
        let storedToken = try await tokenStore.token()
        XCTAssertEqual(storedToken, "registered-token")
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://www.panor.tech/api/auth/register")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, [
            "email": "new-user@example.com",
            "password": "secret12",
            "name": "new-user"
        ])
    }

    func testRegistrationReportsCreatedAccountWhenKeychainCannotPersistToken() async throws {
        let response = Data(#"{"success":true,"sessionId":"registered-token","user":{"id":"u_73","name":"created-user","email":"created@example.com","picture":null}}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: response, status: 200)])
        let tokenStore = FailingTokenStore(error: .secureStorageUnavailable(status: -34018))
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        do {
            _ = try await repository.register(credentials: RegistrationCredentials(
                email: "created@example.com",
                password: "secret12",
                name: "created-user"
            ))
            XCTFail("Expected explicit post-registration storage failure")
        } catch let error as AppError {
            XCTAssertEqual(error, .registrationCompletedButSessionUnavailable)
            XCTAssertEqual(error.userMessage, loc(.errorAccountCreatedButCantSave))
        }
    }

    func testGoogleLoginSendsCredentialAndStoresSessionID() async throws {
        let response = Data(#"{"success":true,"sessionId":"google-session","user":{"id":"g_7","name":"Google User","email":"google@example.com","picture":"https://example.com/avatar.png"}}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: response, status: 200)])
        let tokenStore = InMemoryTokenStore()
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        let user = try await repository.googleLogin(idToken: "google-id-token")

        XCTAssertEqual(user.id, "g_7")
        let storedToken = try await tokenStore.token()
        XCTAssertEqual(storedToken, "google-session")
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://www.panor.tech/api/auth/google")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, ["credential": "google-id-token"])
    }

    func testAppleLoginSendsNativeAuthorizationAndStoresSessionID() async throws {
        let response = Data(#"{"success":true,"sessionId":"apple-session","user":{"id":"a_8","name":"Apple User","email":"apple@example.com","picture":null}}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: response, status: 200)])
        let tokenStore = InMemoryTokenStore()
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)
        var name = PersonNameComponents()
        name.givenName = "Apple"
        name.familyName = "User"

        let user = try await repository.appleLogin(
            identityToken: "apple-id-token",
            authorizationCode: "apple-code",
            fullName: name
        )

        XCTAssertEqual(user.id, "a_8")
        let storedToken = try await tokenStore.token()
        XCTAssertEqual(storedToken, "apple-session")
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://www.panor.tech/api/auth/apple")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, [
            "identityToken": "apple-id-token",
            "authorizationCode": "apple-code",
            "givenName": "Apple",
            "familyName": "User"
        ])
    }

    func testLogoutUsesBearerSessionAndClearsKeychain() async throws {
        let response = Data(#"{"success":true}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: response, status: 200)])
        let tokenStore = InMemoryTokenStore(token: "active-session")
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        try await repository.logout()

        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://www.panor.tech/api/auth/logout")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer active-session")
        let storedToken = try await tokenStore.token()
        XCTAssertNil(storedToken)
    }

    func testAuthenticatedRequestUsesBearerTokenAndCanonicalPath() async throws {
        let transport = StubHTTPTransport(stubs: [
            .init(
                data: Data(#"{"success":true,"user":{"id":"u_2","name":"wilson","email":"wilson@example.com","picture":null}}"#.utf8),
                status: 200
            )
        ])
        let tokenStore = InMemoryTokenStore(token: "test-token")
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        let user = try await repository.currentUser()

        XCTAssertEqual(user?.username, "wilson")
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://www.panor.tech/api/auth/me")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func testAuthMessageFailurePreservesBackendMessage() async {
        let body = Data(#"{"success":false,"message":"Invalid email or password"}"#.utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: body, status: 401)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        do {
            let _: AuthResponse = try await client.request(
                baseURL: APIEnvironment.production.authAPIBaseURL,
                path: AuthAPIPath.login.rawValue,
                method: "POST",
                body: LoginCredentials(identifier: "wilson@example.com", password: "wrong")
            )
            XCTFail("Expected authentication failure")
        } catch let error as AppError {
            XCTAssertEqual(error, .server(status: 401, code: nil, message: "Invalid email or password"))
        } catch {
            XCTFail("Expected AppError")
        }
    }

    func testMissingCurrentUserClearsExpiredSession() async throws {
        let transport = StubHTTPTransport(stubs: [
            .init(data: Data(#"{"success":true,"user":null}"#.utf8), status: 200)
        ])
        let tokenStore = InMemoryTokenStore(token: "expired-session")
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let repository = PanorIdentityRepository(environment: .production, client: client, tokenStore: tokenStore)

        let user = try await repository.currentUser()

        XCTAssertNil(user)
        let storedToken = try await tokenStore.token()
        XCTAssertNil(storedToken)
    }

    func testStructuredServiceFailureIsNotConvertedToSuccess() async throws {
        let body = Data("{\"detail\":{\"code\":\"ai_title_unavailable\",\"message\":\"temporarily unavailable\"}}".utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: body, status: 503)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        do {
            let _: TitleSuggestion = try await client.request(
                baseURL: APIEnvironment.production.soundscapeAPIBaseURL,
                path: SoundscapeAPIPath.aiTitle.value,
                method: "POST",
                body: TitleSuggestionRequest(locationName: "", promptText: "", personalSocial: 0.5, memoryPresent: 0.5)
            )
            XCTFail("Expected explicit service failure")
        } catch let error as AppError {
            XCTAssertEqual(error, .server(status: 503, code: "ai_title_unavailable", message: "temporarily unavailable"))
        }
    }

    func testCommonHTTPFailuresPreserveStatusAndTextDetail() async {
        for status in [401, 403, 404, 422, 503] {
            let transport = StubHTTPTransport(stubs: [
                .init(data: Data("{\"detail\":\"failure-\(status)\"}".utf8), status: status)
            ])
            let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

            do {
                let _: MutationResponse = try await client.request(
                    baseURL: APIEnvironment.production.soundscapeAPIBaseURL,
                    path: SoundscapeAPIPath.health.value
                )
                XCTFail("Expected HTTP \(status) failure")
            } catch let error as AppError {
                XCTAssertEqual(error, .server(status: status, code: nil, message: "failure-\(status)"))
            } catch {
                XCTFail("Expected AppError for HTTP \(status)")
            }
        }
    }

    func testAuthenticatedRequestWithoutTokenFailsBeforeTransport() async {
        let transport = StubHTTPTransport(stubs: [])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())

        do {
            let _: PanorUser = try await client.request(
                baseURL: APIEnvironment.production.authAPIBaseURL,
                path: AuthAPIPath.me.rawValue,
                authenticated: true
            )
            XCTFail("Expected authentication requirement")
        } catch let error as AppError {
            XCTAssertEqual(error, .authenticationRequired)
        } catch {
            XCTFail("Expected AppError")
        }
        let requests = await transport.requests
        XCTAssertTrue(requests.isEmpty)
    }

    func testCoverGenerationUsesLongRunningRequestTimeout() async throws {
        let body = Data("{\"cover_url\":\"/soundscape/uploads/covers/generated.png\",\"cover_is_ai\":1}".utf8)
        let transport = StubHTTPTransport(stubs: [.init(data: body, status: 200)])
        let client = APIClient(transport: transport, tokenStore: InMemoryTokenStore())
        let repository = RemoteSoundscapeRepository(environment: .production, client: client)

        _ = try await repository.suggestCover(CoverSuggestionRequest(title: "雨巷", locationName: "香港", mood: "地方"))

        let requests = await transport.requests
        XCTAssertEqual(requests.first?.timeoutInterval, 180)
    }
}
