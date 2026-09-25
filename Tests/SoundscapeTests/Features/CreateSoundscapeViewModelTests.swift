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
        await model.suggestTitle()
        await model.suggestCover()

        XCTAssertTrue(model.hasCover)
        XCTAssertTrue(model.canPublish)
        await model.publish()
        guard case .published = model.phase else { return XCTFail("Expected published state") }
        let draft = await repository.createdDraft
        XCTAssertEqual(draft?.title, "雨落站台")
        XCTAssertEqual(draft?.description, "列车离开后，雨声留在空站台。")
        XCTAssertEqual(draft?.locationName, "香港 · 中环")
    }

    func testFailedAISuggestionLeavesEditablePublishableDraftWithoutCover() async {
        let repository = StubSoundscapeRepository()
        await repository.setTitleResult(.failure(.server(status: 503, code: "ai_title_unavailable", message: "quota")))
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: StubLocationProvider())
        await model.useImportedAudio(data: Data([1]), filename: "Raining at Night.WAV", contentType: "audio/wav")
        await model.suggestTitle()
        XCTAssertNotNil(model.generationError)
        XCTAssertEqual(model.title, "Raining at Night")
        XCTAssertEqual(model.phase, .review)
        XCTAssertTrue(model.canPublish)
        await model.publish()
        guard case .published = model.phase else { return XCTFail("An optional AI failure must not block publishing") }
        let draft = await repository.createdDraft
        XCTAssertNil(draft?.cover)
        XCTAssertEqual(draft?.title, "Raining at Night")
    }

    func testImportingAnotherRecordingDoesNotKeepThePreviousArtworkOrMemo() async {
        let model = CreateSoundscapeViewModel(repository: StubSoundscapeRepository(), recorder: StubRecordingService(), location: StubLocationProvider())
        await model.useImportedAudio(data: Data([1]), filename: "first.wav", contentType: "audio/wav")
        await model.suggestCover()
        model.description = "memo for first recording"
        XCTAssertTrue(model.hasCover)
        await model.useImportedAudio(data: Data([2]), filename: "second.wav", contentType: "audio/wav")
        XCTAssertFalse(model.hasCover)
        XCTAssertEqual(model.title, "second")
        XCTAssertTrue(model.description.isEmpty)
    }

    func testPublishRejectsOverlongTitleWithoutCallingRepository() async {
        let repository = StubSoundscapeRepository()
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: StubLocationProvider())
        await model.useImportedAudio(data: Data([1]), filename: "sample.m4a", contentType: "audio/mp4")
        model.title = String(repeating: "声", count: DraftConstraints.maximumTitleCharacters + 1)

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

    func testLocationFailureDoesNotBlockManualSuggestion() async {
        let repository = StubSoundscapeRepository()
        let location = StubLocationProvider()
        await location.setResult(.failure(.locationUnavailable))
        let model = CreateSoundscapeViewModel(repository: repository, recorder: StubRecordingService(), location: location)

        await model.prepare()
        await model.useImportedAudio(data: Data([1]), filename: "sample.m4a", contentType: "audio/mp4")
        await model.suggestTitle()
        await model.suggestCover()

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
