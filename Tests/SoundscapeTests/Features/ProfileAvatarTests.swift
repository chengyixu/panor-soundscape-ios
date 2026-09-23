import UIKit
import XCTest
@testable import Soundscape

@MainActor
final class ProfileAvatarTests: XCTestCase {
    func testFirstSignInAssignsOneAvatarAndRestoreKeepsIt() async throws {
        let store = InMemoryProfileAvatarStore()
        let repository = StubIdentityRepository()
        let session = IdentitySession(repository: repository, avatarStore: store)
        try await session.login(identifier: "wilson", password: "secret")
        await repository.setCurrentUserResult(.success(session.user))
        let first = try XCTUnwrap(session.avatar)
        guard case .generated(let index) = first else { return XCTFail("Expected generated avatar") }
        XCTAssertTrue((0..<ProfileAvatar.generatedCount).contains(index))

        await session.restore()
        XCTAssertEqual(session.avatar, first)
        let creationCount = await store.creationCount
        XCTAssertEqual(creationCount, 1)
    }

    func testAvatarStorageFailureDoesNotUndoSuccessfulRegistration() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data([1]).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = DiskProfileAvatarStore(directory: file)
        let session = IdentitySession(repository: StubIdentityRepository(), avatarStore: store)

        try await session.register(name: "new", email: "new@example.com", password: "secret12")

        XCTAssertNotNil(session.user)
        XCTAssertNil(session.avatar)
        XCTAssertNotNil(session.avatarError)
        XCTAssertNil(session.error, "An avatar disk failure must not be reported as an auth failure")
    }

    func testPhotoReplacesOnlyCurrentAccountAndSurvivesRestore() async throws {
        let store = InMemoryProfileAvatarStore()
        let repository = StubIdentityRepository()
        let session = IdentitySession(repository: repository, avatarStore: store)
        try await session.login(identifier: "wilson", password: "secret")
        await repository.setCurrentUserResult(.success(session.user))
        let original = try XCTUnwrap(session.avatar)
        let photo = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try await session.setAvatarPhoto(photo, for: "u_2")
        XCTAssertEqual(session.avatar, .photo(photo))
        await session.restore()
        XCTAssertEqual(session.avatar, .photo(photo))

        await repository.setCurrentUserResult(.success(PanorUser(id: "other", name: "Other", email: "other@example.com", picture: nil)))
        await session.restore()
        XCTAssertNotEqual(session.avatar, .photo(photo))
        await repository.setCurrentUserResult(.success(PanorUser(id: "u_2", name: "wilson", email: "wilson@example.com", picture: nil)))
        await session.restore()
        XCTAssertEqual(session.avatar, .photo(photo))
        XCTAssertNotEqual(original, .photo(photo))
    }

    func testSwitchingAccountsNeverDisplaysPreviousAvatarDuringLoad() async throws {
        let store = InMemoryProfileAvatarStore()
        let repository = StubIdentityRepository()
        let session = IdentitySession(repository: repository, avatarStore: store)
        try await session.login(identifier: "wilson", password: "secret")
        try await session.setAvatarPhoto(Data([1, 2, 3]), for: "u_2")
        await repository.setCurrentUserResult(.success(PanorUser(id: "other", name: "Other", email: "other@example.com", picture: nil)))
        await store.suspendNextLoad()
        let restoring = Task { await session.restore() }
        for _ in 0..<100 {
            if await store.isWaiting { break }
            await Task.yield()
        }
        let waiting = await store.isWaiting
        XCTAssertTrue(waiting)
        XCTAssertNil(session.avatar, "Previous account photo must disappear before next account loads")
        await store.resumeLoad()
        await restoring.value
        XCTAssertNotEqual(session.avatar, .photo(Data([1, 2, 3])))
    }

    func testFailedPhotoSaveKeepsPreviousAvatarAndSurfacesError() async throws {
        let store = InMemoryProfileAvatarStore()
        let session = IdentitySession(repository: StubIdentityRepository(), avatarStore: store)
        try await session.login(identifier: "wilson", password: "secret")
        let previous = session.avatar
        await store.failNextSave()
        do {
            try await session.setAvatarPhoto(Data([1, 2, 3]), for: "u_2")
            XCTFail("Expected write failure")
        } catch {}
        XCTAssertEqual(session.avatar, previous)
    }

    func testDiskStorePersistsAndSeparatesUsersAcrossInstances() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let firstStore = DiskProfileAvatarStore(directory: directory)
        let first = try await firstStore.avatar(for: "u_2")
        let recreated = DiskProfileAvatarStore(directory: directory)
        let restored = try await recreated.avatar(for: "u_2")
        XCTAssertEqual(restored, first)
        let other = try await recreated.avatar(for: "u_3")
        XCTAssertNotEqual(other, .photo(Data([7, 8])))
        try await recreated.save(photo: Data([7, 8]), for: "u_2")
        let updated = try await firstStore.avatar(for: "u_2")
        XCTAssertEqual(updated, .photo(Data([7, 8])))
        let otherAfterUpdate = try await firstStore.avatar(for: "u_3")
        XCTAssertNotEqual(otherAfterUpdate, .photo(Data([7, 8])))
    }

    func testImageProcessorProducesSquareBoundedOpaqueJPEGAndRejectsInvalidInput() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 400)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 400))
        }
        let jpeg = try ProfileAvatarImageProcessor.normalizedJPEG(from: try XCTUnwrap(image.pngData()))
        let normalized = try XCTUnwrap(UIImage(data: jpeg))
        XCTAssertEqual(normalized.size, CGSize(width: 256, height: 256))
        XCTAssertLessThan(jpeg.count, 256_000)
        XCTAssertThrowsError(try ProfileAvatarImageProcessor.normalizedJPEG(from: Data([0, 1])))
    }
}

actor InMemoryProfileAvatarStore: ProfileAvatarStore {
    private var values: [String: ProfileAvatar] = [:]
    private(set) var creationCount = 0
    private var fails = false
    private var nextLoadSuspended = false
    private var loadContinuation: CheckedContinuation<Void, Never>?
    var isWaiting: Bool { loadContinuation != nil }

    func avatar(for id: String) async throws -> ProfileAvatar {
        if nextLoadSuspended {
            nextLoadSuspended = false
            await withCheckedContinuation { continuation in loadContinuation = continuation }
        }
        if let value = values[id] { return value }
        let value = ProfileAvatar.generated(Int.random(in: 0..<ProfileAvatar.generatedCount))
        values[id] = value
        creationCount += 1
        return value
    }

    func save(photo: Data, for id: String) throws {
        if fails { fails = false; throw AppError.secureStorageUnavailable(status: -1) }
        values[id] = .photo(photo)
    }

    func failNextSave() { fails = true }
    func suspendNextLoad() { nextLoadSuspended = true }
    func resumeLoad() { loadContinuation?.resume(); loadContinuation = nil }
}
