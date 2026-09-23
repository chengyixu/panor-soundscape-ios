import Foundation

enum ProfileAvatar: Codable, Equatable, Sendable {
    static let generatedCount = 8

    case generated(Int)
    case photo(Data)
}

protocol ProfileAvatarStore: Sendable {
    func avatar(for userID: String) async throws -> ProfileAvatar
    func save(photo: Data, for userID: String) async throws
}
