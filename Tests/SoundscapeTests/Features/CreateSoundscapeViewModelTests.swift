import XCTest
@testable import Soundscape

actor StubRecordingService: RecordingService {
    func start() async throws {}
    func stop() async throws -> MediaFile { MediaFile(data: Data([1, 2]), filename: "recording.m4a", contentType: "audio/mp4") }
    func cancel() async {}
}

actor StubLocationProvider: LocationProviding {
    private(set) var callCount = 0
    var result: Result<Place, AppError> = .success(Place(latitude: 22.3, longitude: 114.2, name: "香港 · 中环"))

    func currentPlace() async throws -> Place {
        callCount += 1
        return try result.get()
    }
}

@MainActor
final class CreateSoundscapeViewModelTests: XCTestCase {
    func testGeneratedCoverAndAudioProducePublishableDraft() async {
        let repository = StubSoundscapeRepository()
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: StubLocationProvider())
        await model.prepare()
        await model.useImportedAudio(data: Data([1]), filename: "sample.m4a", contentType: "audio/mp4")

        XCTAssertTrue(model.hasCover)
        XCTAssertTrue(model.canPublish)
        await model.publish()
        guard case .published = model.phase else { return XCTFail("Expected published state") }
        let draft = await repository.createdDraft
        XCTAssertEqual(draft?.title, "雨落站台")
        XCTAssertEqual(draft?.description, "列车离开后，雨声留在空站台。")
        XCTAssertEqual(draft?.locationName, "香港 · 中环")
    }

    func testPublishRejectsOverlongTitleWithoutCallingRepository() async {
        let repository = StubSoundscapeRepository()
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: StubLocationProvider())
        await model.useImportedAudio(data: Data([1]), filename: "sample.m4a", contentType: "audio/mp4", generateAutomatically: false)
        model.title = String(repeating: "声", count: DraftConstraints.maximumTitleCharacters + 1)
        await model.suggestCover()

        await model.publish()

        XCTAssertEqual(model.phase, .failed(.invalidRequest(loc(.errorTitleTooLong))))
        let draft = await repository.createdDraft
        XCTAssertNil(draft)
    }

    func testPrepareAutomaticallyRequestsLocationOnce() async {
        let repository = StubSoundscapeRepository()
        let location = StubLocationProvider()
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: location)

        await model.prepare()
        await model.prepare()

        XCTAssertEqual(model.place?.name, "香港 · 中环")
        let callCount = await location.callCount
        XCTAssertEqual(callCount, 1)
    }

    func testLocationFailureDoesNotBlockRecordingOrAutomaticAI() async {
        let repository = StubSoundscapeRepository()
        let location = StubLocationProvider()
        await location.setResult(.failure(.locationUnavailable))
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: location)

        await model.prepare()
        await model.useImportedAudio(data: Data([1]), filename: "sample.m4a", contentType: "audio/mp4")

        XCTAssertEqual(model.locationStatus, .unavailable)
        XCTAssertEqual(model.phase, .review)
        XCTAssertEqual(model.title, "雨落站台")
        XCTAssertTrue(model.hasCover)
    }
}

private extension StubLocationProvider {
    func setResult(_ result: Result<Place, AppError>) {
        self.result = result
    }
}
