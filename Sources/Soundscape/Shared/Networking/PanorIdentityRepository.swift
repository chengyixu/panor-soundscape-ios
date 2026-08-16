import Foundation

actor PanorIdentityRepository: IdentityRepository {
    private let environment: APIEnvironment
    private let client: APIClient
    private let tokenStore: any AuthTokenStore

    init(environment: APIEnvironment, client: APIClient, tokenStore: any AuthTokenStore) {
        self.environment = environment
        self.client = client
        self.tokenStore = tokenStore
    }

    func register(credentials: RegistrationCredentials) async throws -> PanorUser {
        let response: AuthResponse = try await client.request(
            baseURL: environment.authAPIBaseURL,
            path: AuthAPIPath.register.rawValue,
            method: "POST",
            body: credentials
        )
        do {
            try await tokenStore.setToken(response.sessionId)
        } catch AppError.secureStorageUnavailable(status: _) {
            throw AppError.registrationCompletedButSessionUnavailable
        }
        return response.user
    }

    func login(credentials: LoginCredentials) async throws -> PanorUser {
        let response: AuthResponse = try await client.request(
            baseURL: environment.authAPIBaseURL,
            path: AuthAPIPath.login.rawValue,
            method: "POST",
            body: credentials
        )
        try await tokenStore.setToken(response.sessionId)
        return response.user
    }

    func googleLogin(idToken: String) async throws -> PanorUser {
        let body = ["credential": idToken]
        let response: AuthResponse = try await client.request(
            baseURL: environment.authAPIBaseURL,
            path: AuthAPIPath.google.rawValue,
            method: "POST",
            body: body
        )
        try await tokenStore.setToken(response.sessionId)
        return response.user
    }

    func appleLogin(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?) async throws -> PanorUser {
        var body: [String: String] = [
            "identityToken": identityToken,
            "authorizationCode": authorizationCode
        ]
        if let givenName = fullName?.givenName {
            body["givenName"] = givenName
        }
        if let familyName = fullName?.familyName {
            body["familyName"] = familyName
        }
        let response: AuthResponse = try await client.request(
            baseURL: environment.authAPIBaseURL,
            path: AuthAPIPath.apple.rawValue,
            method: "POST",
            body: body
        )
        try await tokenStore.setToken(response.sessionId)
        return response.user
    }

    func currentUser() async throws -> PanorUser? {
        guard let token = try await tokenStore.token(), !token.isEmpty else { return nil }
        do {
            let response: CurrentUserResponse = try await client.request(
                baseURL: environment.authAPIBaseURL,
                path: AuthAPIPath.me.rawValue,
                authenticated: true
            )
            guard let user = response.user else {
                try await tokenStore.clear()
                return nil
            }
            return user
        } catch AppError.server(status: 401, code: _, message: _) {
            try await tokenStore.clear()
            return nil
        }
    }

    func logout() async throws {
        do {
            let _: AuthMutationResponse = try await client.request(
                baseURL: environment.authAPIBaseURL,
                path: AuthAPIPath.logout.rawValue,
                method: "POST",
                authenticated: true
            )
        } catch AppError.server(status: 401, code: _, message: _) {}
        try await tokenStore.clear()
    }
}
