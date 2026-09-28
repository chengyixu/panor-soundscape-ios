import UIKit
import SwiftUI
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

    func testGeneratedAvatarIsStableForEveryCreatorOnEveryDevice() async throws {
        let first = ProfileAvatar.generatedIndex(for: "source:freesound")
        XCTAssertEqual(first, ProfileAvatar.generatedIndex(for: "source:freesound"))
        XCTAssertTrue((0..<ProfileAvatar.generatedCount).contains(first))
        let samples = (0..<20).map { ProfileAvatar.generatedIndex(for: "creator-\($0)") }
        XCTAssertGreaterThan(Set(samples).count, 4)

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DiskProfileAvatarStore(directory: directory)
        let local = try await store.avatar(for: "source:freesound")
        XCTAssertEqual(local, .generated(first))
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

    func testAllCreatorSurfacesResolveUpdatedPhotoFromSameObservableStore() async throws {
        let store = InMemoryProfileAvatarStore()
        let session = IdentitySession(repository: StubIdentityRepository(), avatarStore: store)
        try await session.login(identifier: "wilson", password: "secret")
        let photo = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try await session.setAvatarPhoto(photo, for: "u_2")
        XCTAssertEqual(session.avatars.avatar(for: "u_2"), .photo(photo))
        XCTAssertEqual(session.avatars.avatar(for: "u_2"), session.avatar)
        XCTAssertNotEqual(session.avatars.avatar(for: "other"), .photo(photo))
        let restored = CreatorAvatarResolver(store: store)
        try await restored.load(for: "u_2")
        XCTAssertEqual(restored.avatar(for: "u_2"), .photo(photo))
    }

    func testCreatorAvatarRendersUpdatedPhotoWithoutReopeningScreen() async throws {
        let session = IdentitySession(repository: StubIdentityRepository(), avatarStore: InMemoryProfileAvatarStore())
        try await session.login(identifier: "wilson", password: "secret")
        let portrait = CreatorAvatar(creatorID: "u_2", size: 68).environment(session.avatars)
        let before = try XCTUnwrap(ImageRenderer(content: portrait).uiImage?.pngData())
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 68, height: 68)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 68, height: 68))
        }
        try await session.setAvatarPhoto(try XCTUnwrap(photo.jpegData(compressionQuality: 0.9)), for: "u_2")
        let after = try XCTUnwrap(ImageRenderer(content: portrait).uiImage?.pngData())
        let anotherSurface = CreatorAvatar(creatorID: "u_2", size: 68).environment(session.avatars)
        let elsewhere = try XCTUnwrap(ImageRenderer(content: anotherSurface).uiImage?.pngData())
        XCTAssertNotEqual(before, after)
        XCTAssertEqual(after, elsewhere)
    }

    func testMultipleCreatorPortraitsShareOneInFlightDiskRead() async throws {
        let store = InMemoryProfileAvatarStore()
        let avatars = CreatorAvatarResolver(store: store)
        await store.suspendNextLoad()
        let first = Task { try await avatars.load(for: "u_2") }
        for _ in 0..<1000 {
            if await store.isWaiting { break }
            await Task.yield()
        }
        let second = Task { try await avatars.load(for: "u_2") }
        for _ in 0..<100 { await Task.yield() }
        await store.resumeLoad()
        try await first.value
        try await second.value
        let reads = await store.loadCount
        XCTAssertEqual(reads, 1)
    }

    func testAnOlderAvatarReadCannotOverwriteANewPhoto() async throws {
        let store = InMemoryProfileAvatarStore()
        let avatars = CreatorAvatarResolver(store: store)
        await store.suspendNextLoad()
        let loading = Task { try await avatars.load(for: "u_2") }
        for _ in 0..<1000 {
            if await store.isWaiting { break }
            await Task.yield()
        }
        let photo = Data([1, 2, 3])
        try await avatars.save(photo: photo, for: "u_2")
        await store.resumeLoad()
        try await loading.value
        XCTAssertEqual(avatars.avatar(for: "u_2"), .photo(photo))
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
    private(set) var loadCount = 0
    private var fails = false
    private var nextLoadSuspended = false
    private var loadContinuation: CheckedContinuation<Void, Never>?
    var isWaiting: Bool { loadContinuation != nil }

    func avatar(for id: String) async throws -> ProfileAvatar {
        loadCount += 1
        let captured: ProfileAvatar
        if let value = values[id] { captured = value }
        else {
            captured = .generated(ProfileAvatar.generatedIndex(for: id))
            values[id] = captured
            creationCount += 1
        }
        if nextLoadSuspended {
            nextLoadSuspended = false
            await withCheckedContinuation { continuation in loadContinuation = continuation }
        }
        return captured
    }

    func save(photo: Data, for id: String) throws {
        if fails { fails = false; throw AppError.secureStorageUnavailable(status: -1) }
        values[id] = .photo(photo)
    }

    func failNextSave() { fails = true }
    func suspendNextLoad() { nextLoadSuspended = true }
    func resumeLoad() { loadContinuation?.resume(); loadContinuation = nil }
}
