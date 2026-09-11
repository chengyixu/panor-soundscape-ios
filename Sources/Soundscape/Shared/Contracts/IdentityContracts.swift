import Foundation

struct PanorUser: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let email: String
    let picture: String?

    var username: String { name }
}

struct LoginCredentials: Encodable, Equatable, Sendable {
    let identifier: String
    let password: String
}

struct RegistrationCredentials: Encodable, Equatable, Sendable {
    let email: String
    let password: String
    let name: String?
}

struct AuthResponse: Decodable, Sendable {
    let success: Bool
    let user: PanorUser
    let sessionId: String
}

struct CurrentUserResponse: Decodable, Sendable {
    let success: Bool
    let user: PanorUser?
}

struct AuthMutationResponse: Decodable, Sendable {
    let success: Bool
}

protocol AuthTokenStore: Sendable {
    func token() async throws -> String?
    func setToken(_ token: String) async throws
    func clear() async throws
}

protocol IdentityRepository: Sendable {
    func register(credentials: RegistrationCredentials) async throws -> PanorUser
    func login(credentials: LoginCredentials) async throws -> PanorUser
    func googleLogin(idToken: String) async throws -> PanorUser
    func appleLogin(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?) async throws -> PanorUser
    func currentUser() async throws -> PanorUser?
    func logout() async throws
}
