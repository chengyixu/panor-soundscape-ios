import Foundation
import Observation

@MainActor
@Observable
final class IdentitySession {
    private(set) var user: PanorUser?
    private(set) var isRestoring = false
    private(set) var error: AppError?

    private let repository: any IdentityRepository

    init(repository: any IdentityRepository) {
        self.repository = repository
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            user = try await repository.currentUser()
            error = nil
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
    }

    func login(identifier: String, password: String) async throws {
        user = try await repository.login(credentials: LoginCredentials(identifier: identifier, password: password))
        error = nil
    }

    func googleLogin(idToken: String) async throws {
        user = try await repository.googleLogin(idToken: idToken)
        error = nil
    }

    func appleLogin(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?) async throws {
        user = try await repository.appleLogin(identityToken: identityToken, authorizationCode: authorizationCode, fullName: fullName)
        error = nil
    }

    func register(name: String?, email: String, password: String) async throws {
        user = try await repository.register(credentials: RegistrationCredentials(
            email: email,
            password: password,
            name: name
        ))
        error = nil
    }

    func logout() async {
        do {
            try await repository.logout()
            user = nil
            error = nil
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
    }
}
