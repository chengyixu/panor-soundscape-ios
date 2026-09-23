import Foundation
import Observation

@MainActor
@Observable
final class IdentitySession {
    private(set) var user: PanorUser?
    private(set) var avatar: ProfileAvatar?
    private(set) var avatarError: AppError?
    private(set) var isRestoring = false
    private(set) var error: AppError?

    private let repository: any IdentityRepository
    private let avatarStore: any ProfileAvatarStore

    init(repository: any IdentityRepository, avatarStore: any ProfileAvatarStore) {
        self.repository = repository
        self.avatarStore = avatarStore
    }

    private func assignUser(_ next: PanorUser?) async {
        guard let next else { user = nil; avatar = nil; avatarError = nil; return }
        if user?.id != next.id { avatar = nil }
        user = next
        do {
            let resolved = try await avatarStore.avatar(for: next.id)
            if user?.id == next.id { avatar = resolved; avatarError = nil }
        } catch {
            if user?.id == next.id {
                avatar = nil
                avatarError = .invalidRequest(loc(.errorCannotProcessImage))
            }
        }
    }

    func dismissAvatarError() {
        avatarError = nil
    }

    func setAvatarPhoto(_ data: Data, for userID: String) async throws {
        guard user?.id == userID else { throw AppError.authenticationRequired }
        try await avatarStore.save(photo: data, for: userID)
        if user?.id == userID { avatar = .photo(data); avatarError = nil }
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            let next = try await repository.currentUser()
            error = nil
            await assignUser(next)
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
    }

    func login(identifier: String, password: String) async throws {
        let next = try await repository.login(credentials: LoginCredentials(identifier: identifier, password: password))
        error = nil
        await assignUser(next)
    }

    func googleLogin(idToken: String) async throws {
        let next = try await repository.googleLogin(idToken: idToken)
        error = nil
        await assignUser(next)
    }

    func appleLogin(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?) async throws {
        let next = try await repository.appleLogin(identityToken: identityToken, authorizationCode: authorizationCode, fullName: fullName)
        error = nil
        await assignUser(next)
    }

    func register(name: String?, email: String, password: String) async throws {
        let next = try await repository.register(credentials: RegistrationCredentials(
            email: email,
            password: password,
            name: name
        ))
        error = nil
        await assignUser(next)
    }

    func logout() async {
        do {
            try await repository.logout()
            user = nil
            avatar = nil
            avatarError = nil
            error = nil
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
    }
}
