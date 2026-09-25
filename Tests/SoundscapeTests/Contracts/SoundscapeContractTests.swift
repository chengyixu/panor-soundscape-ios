import XCTest
@testable import Soundscape

final class SoundscapeContractTests: XCTestCase {
    func testFileExtensionIsNotPartOfDisplayedVoiceName() {
        var item = TestFixtures.soundscape
        item = Soundscape(
            id: item.id, ownerID: item.ownerID, authorName: item.authorName,
            title: "Rain.wav on metal roof.WAV", description: item.description,
            audioURL: item.audioURL, coverURL: item.coverURL, coverIsAI: item.coverIsAI,
            latitude: item.latitude, longitude: item.longitude, locationName: item.locationName,
            category: item.category, promptText: item.promptText,
            personalSocial: item.personalSocial, memoryPresent: item.memoryPresent,
            durationSeconds: item.durationSeconds, isPublic: item.isPublic,
            playCount: item.playCount, fullPlayCount: item.fullPlayCount,
            saveCount: item.saveCount, createdAt: item.createdAt
        )
        XCTAssertEqual(item.displayTitle, "Rain on metal roof")
    }

    func testDecodesProductionShapeAndResolvesRelativeMediaURLs() throws {
        let json = """
        {"id":17,"user_id":"2","author_name":"wilsonxu","title":"九巷风藏旧语声","description":"声响里裹着旧念。","audio_url":"/soundscape/uploads/audio/sample.m4a","cover_url":"/soundscape/uploads/covers/sample.png","cover_is_ai":1,"lat":22.579,"lng":113.861,"location_name":"盐田新一村九巷","category":"地方","prompt_text":"录下一段声音","tag_personal_social":0.5,"tag_memory_present":0.5,"duration_sec":699,"is_public":1,"play_count":2,"full_play_count":0,"save_count":0,"created_at":"2026-07-17 13:51:30","world":{"status":"ready","format":"spz","provenance":"ai_gaussian","updated_at":"2026-07-21 20:00:00","assets":{"preview":{"url":"/soundscape/uploads/worlds/17/preview-a.spz","format":"spz","sha256":"aaa","bytes":100},"standard":{"url":"/soundscape/uploads/worlds/17/standard-b.spz","format":"spz","sha256":"bbb","bytes":200}}}}
        """
        let dto = try JSONDecoder().decode(SoundscapeDTO.self, from: Data(json.utf8))
        let item = dto.domain(environment: .production)

        XCTAssertEqual(item.id, 17)
        XCTAssertEqual(item.authorDisplay, "wilsonxu")
        XCTAssertEqual(item.audioURL?.absoluteString, "https://www.panor.tech/soundscape/uploads/audio/sample.m4a")
        XCTAssertEqual(item.coverURL?.absoluteString, "https://www.panor.tech/soundscape/uploads/covers/sample.png")
        XCTAssertTrue(item.coverIsAI)
        XCTAssertTrue(item.isPublic)
        XCTAssertEqual(item.world.status, .ready)
        XCTAssertEqual(item.world.assets?.standard.url.absoluteString, "https://www.panor.tech/soundscape/uploads/worlds/17/standard-b.spz")
        XCTAssertEqual(item.world.assets?.standard.format, "spz")
    }

    func testReadyWorldWithoutTwoValidSPZAssetsFailsClosed() throws {
        let json = """
        {"id":1,"world":{"status":"ready","format":"spz","provenance":"ai_gaussian","assets":{"preview":{"url":"/preview.spz","format":"spz","sha256":"a","bytes":10},"standard":{"url":"/world.data","format":"binary","sha256":"b","bytes":20}}}}
        """
        let dto = try JSONDecoder().decode(SoundscapeDTO.self, from: Data(json.utf8))
        let item = dto.domain(environment: .production)

        XCTAssertEqual(item.world.status, .failed)
        XCTAssertNil(item.world.assets)
    }

    func testDecodesManagedProviderLifecycleAndAIGaussianProvenance() throws {
        let json = """
        [
          {"id":16,"world":{"status":"ready","format":"spz","provenance":"ai_gaussian","assets":{"preview":{"url":"/preview.spz","format":"spz","sha256":"a","bytes":10},"standard":{"url":"/standard.spz","format":"spz","sha256":"b","bytes":20}}}},
          {"id":17,"world":{"status":"awaiting_gaussian","format":"spz","provenance":"ai_gaussian"}},
          {"id":18,"world":{"status":"preparing","format":"spz","provenance":"ai_gaussian"}}
        ]
        """

        let rows = try JSONDecoder().decode([SoundscapeDTO].self, from: Data(json.utf8))
        let worlds = rows.map { $0.domain(environment: .production).world }

        XCTAssertEqual(worlds.map(\.status), [.ready, .awaitingGaussian, .preparing])
        XCTAssertTrue(worlds.allSatisfy { $0.provenance == "ai_gaussian" })
        XCTAssertNotNil(worlds[0].assets)
    }

    func testUnknownWorldStatusFailsClosedWithoutBreakingSoundscapeList() throws {
        let json = #"[{"id":1,"world":{"status":"provider_future_state","format":"spz","provenance":"ai_gaussian"}}]"#
        let rows = try JSONDecoder().decode([SoundscapeDTO].self, from: Data(json.utf8))

        XCTAssertEqual(rows.first?.domain(environment: .production).world.status, .failed)
    }

    func testMultipartUsesCanonicalFastAPIFieldNames() {
        var builder = MultipartBuilder()
        builder.addFile(name: "audio", file: MediaFile(data: Data([0x01]), filename: "recording.m4a", contentType: "audio/mp4"))
        builder.addField(name: "tag_personal_social", value: "0.5")
        builder.addField(name: "tag_memory_present", value: "0.5")
        builder.addField(name: "is_public", value: "1")
        let text = String(decoding: builder.build().data, as: UTF8.self)

        XCTAssertTrue(text.contains("name=\"audio\""))
        XCTAssertTrue(text.contains("name=\"tag_personal_social\""))
        XCTAssertTrue(text.contains("name=\"tag_memory_present\""))
        XCTAssertTrue(text.contains("name=\"is_public\""))
    }
}
