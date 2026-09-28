import SwiftUI

struct ThemeArtwork: View {
    let themeID: Int
    let size: CGFloat
    var body: some View { SoundscapeAvatar(seed: "theme:\(themeID)", size: size) }
}
