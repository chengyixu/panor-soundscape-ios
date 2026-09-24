import Foundation

enum ModerationDecision: String, Sendable {
    case approve
    case reject
    case remove
}

struct ModerationReport: Decodable, Identifiable, Sendable {
    let id: Int
    let soundscape_id: Int
    let reason: String
    let title: String
    let author_id: String
    let has_cover: Bool
    let created_at: String
}

protocol ModerationRepository: Sendable {
    func report(soundscapeID: Int, reason: String) async throws
    func block(creatorID: String) async throws
    func hasModeratorAccess() async throws -> Bool
    func pending() async throws -> [Soundscape]
    func reports() async throws -> [ModerationReport]
    func previewAudio(soundscapeID: Int) async throws -> Data
    func previewCover(soundscapeID: Int) async throws -> Data
    func resolveReport(id: Int) async throws
    func decide(soundscapeID: Int, action: ModerationDecision) async throws
    func suspendCreator(id: String) async throws
}
