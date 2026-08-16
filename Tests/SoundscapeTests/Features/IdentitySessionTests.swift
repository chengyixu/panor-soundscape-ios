import XCTest
@testable import Soundscape

@MainActor
final class IdentitySessionTests: XCTestCase {
    func testRestorePublishesExistingUserAndEndsLoading() async {
        let repository = StubIdentityRepository()
        let user = PanorUser(id: "u_2", name: "wilson", email: "wilson@example.com", picture: nil)
        await repository.setCurrentUserResult(.success(user))
        let session = IdentitySession(repository: repository)

        await session.restore()

        XCTAssertEqual(session.user, user)
        XCTAssertFalse(session.isRestoring)
        XCTAssertNil(session.error)
    }

    func testLogoutFailureKeepsUserAndSurfacesError() async throws {
        let repository = StubIdentityRepository()
        await repository.setLogoutResult(.failure(.transport("offline")))
        let session = IdentitySession(repository: repository)
        try await session.login(email: "wilson@example.com", password: "secret")

        await session.logout()

        XCTAssertEqual(session.user?.username, "wilson")
        XCTAssertEqual(session.error, .transport("offline"))
    }

    func testRegisterForwardsRequiredEmail() async throws {
        let repository = StubIdentityRepository()
        let session = IdentitySession(repository: repository)

        try await session.register(name: "new-user", email: "new-user@example.com", password: "secret12")

        let credentials = await repository.registrationCredentials
        XCTAssertEqual(credentials, RegistrationCredentials(
            email: "new-user@example.com",
            password: "secret12",
            name: "new-user"
        ))
        XCTAssertEqual(session.user?.username, "new-user")
    }
}
