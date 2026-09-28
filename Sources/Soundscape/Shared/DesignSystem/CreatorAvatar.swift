import SwiftUI

/// All creator portraits resolve through the same AppContainer-owned instance.
/// Recording artwork uses SoundscapeAvatar separately, not an account photo.
struct CreatorAvatar: View {
    @Environment(CreatorAvatarResolver.self) private var avatars
    let creatorID: String
    let size: CGFloat

    var body: some View {
        let value = avatars.avatar(for: creatorID)
        SoundscapeAvatar(seed: creatorID, size: size, photo: photo(in: value))
            .task(id: creatorID) { await avatars.resolve(for: creatorID) }
    }

    private func photo(in value: ProfileAvatar) -> Data? {
        if case .photo(let data) = value { return data }
        return nil
    }
}
