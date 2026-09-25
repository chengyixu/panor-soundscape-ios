import CryptoKit
import Foundation

/// Avatars are local to this installation until unified Panor auth supports an avatar API.
actor DiskProfileAvatarStore: ProfileAvatarStore {
    private let directory: URL

    init(directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Soundscape/Avatars", isDirectory: true)) {
        self.directory = directory
    }

    func avatar(for userID: String) throws -> ProfileAvatar {
        let url = try fileURL(for: userID)
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            let avatar = try JSONDecoder().decode(ProfileAvatar.self, from: data)
            if case .generated = avatar {
                let stable = ProfileAvatar.generated(ProfileAvatar.generatedIndex(for: userID))
                if avatar != stable { try persist(stable, at: url) }
                return stable
            }
            return avatar
        }
        let avatar = ProfileAvatar.generated(ProfileAvatar.generatedIndex(for: userID))
        try persist(avatar, at: url)
        return avatar
    }

    func save(photo: Data, for userID: String) throws {
        guard !photo.isEmpty, photo.count <= 256_000 else { throw AppError.invalidRequest(loc(.errorInvalidImage)) }
        try persist(.photo(photo), at: fileURL(for: userID))
    }

    private func fileURL(for userID: String) throws -> URL {
        guard !userID.isEmpty else { throw AppError.invalidRequest(loc(.errorInvalidParams)) }
        let digest = SHA256.hash(data: Data(userID.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("\(digest).json")
    }

    private func persist(_ avatar: ProfileAvatar, at url: URL) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        try (directory as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)
        try JSONEncoder().encode(avatar).write(to: url, options: [.atomic, .completeFileProtection])
    }
}
