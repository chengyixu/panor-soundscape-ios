import Foundation

enum ProfileAvatar: Codable, Equatable, Sendable {
    static let generatedCount = 32

    /// FNV-1a has a fixed byte order and never relies on randomized Swift Hashable.
    /// One account gets the same visual identity on every installation.
    static func generatedIndex(for userID: String) -> Int {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in userID.utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return Int(hash % UInt64(generatedCount))
    }

    case generated(Int)
    case photo(Data)
}

protocol ProfileAvatarStore: Sendable {
    func avatar(for userID: String) async throws -> ProfileAvatar
    func save(photo: Data, for userID: String) async throws
}
