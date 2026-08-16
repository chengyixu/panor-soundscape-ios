import XCTest
@testable import Soundscape

final class MediaConstraintsTests: XCTestCase {
    func testAcceptsSupportedAudioWithinUploadLimit() throws {
        let file = try MediaConstraints.audio(
            data: Data(repeating: 0x01, count: 16),
            filename: "field.m4a",
            contentType: "audio/mp4"
        )

        XCTAssertEqual(file.filename, "field.m4a")
    }

    func testRejectsEmptyAndOversizedAudio() {
        XCTAssertThrowsError(try MediaConstraints.audio(data: Data(), filename: "empty.m4a", contentType: "audio/mp4"))
        XCTAssertThrowsError(try MediaConstraints.validateAudioByteCount(MediaConstraints.maximumAudioBytes + 1))
    }

    func testRejectsUnsupportedAudioType() {
        XCTAssertThrowsError(
            try MediaConstraints.audio(data: Data([0x01]), filename: "notes.txt", contentType: "text/plain")
        )
    }

    func testRejectsOversizedCover() {
        XCTAssertThrowsError(try MediaConstraints.validateCoverByteCount(MediaConstraints.maximumCoverBytes + 1))
    }
}
