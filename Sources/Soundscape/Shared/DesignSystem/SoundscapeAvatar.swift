import SwiftUI
import UIKit

/// Local, seed-stable marble artwork. Photos remain authoritative when supplied.
/// Adapted from Boring Avatars Marble; see bundled MIT license and research note.
struct SoundscapeAvatar: View {
    let seed: String
    let size: CGFloat
    var photo: Data? = nil

    var body: some View {
        Group {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                marble
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(.black.opacity(0.08), lineWidth: 0.5) }
        .accessibilityHidden(true)
    }

    private var marble: some View {
        let recipe = MarbleAvatarRecipe(seed: seed)
        let colors = Self.palettes[recipe.palette].map(Self.color)
        return Canvas { context, dimensions in
            context.scaleBy(x: dimensions.width / 80, y: dimensions.height / 80)
            context.fill(Path(CGRect(x: 0, y: 0, width: 80, height: 80)), with: .color(colors[recipe.layers[0].color]))
            for index in 1...2 {
                let layer = recipe.layers[index]
                var drawing = context
                drawing.addFilter(.blur(radius: 7))
                if index == 2 { drawing.blendMode = .overlay }
                drawing.translateBy(x: layer.x, y: layer.y)
                drawing.translateBy(x: 40, y: 40)
                drawing.rotate(by: .degrees(layer.rotation))
                drawing.translateBy(x: -40, y: -40)
                drawing.scaleBy(x: recipe.layers[2].scale, y: recipe.layers[2].scale)
                drawing.fill(Self.shape(index), with: .color(colors[layer.color]))
            }
        }
    }

    private static func shape(_ index: Int) -> Path {
        let points: [CGPoint] = index == 1
            ? [CGPoint(x: 32.414, y: 59.35), CGPoint(x: 50.376, y: 70.5), CGPoint(x: 72.5, y: 70.5), CGPoint(x: 72.5, y: -0.5), CGPoint(x: 33.728, y: -0.5), CGPoint(x: 26.5, y: 13.381), CGPoint(x: 45.557, y: 40.461)]
            : [CGPoint(x: 22.216, y: 24), CGPoint(x: 0, y: 46.75), CGPoint(x: 14.108, y: 84.879), CGPoint(x: 78, y: 86), CGPoint(x: 74.919, y: 26.724), CGPoint(x: 52.541, y: 30.729), CGPoint(x: 65.513, y: 50.915), CGPoint(x: 42.163, y: 78.31)]
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    private static let palettes: [[UInt32]] = [
        [0x243A37, 0x698D7A, 0xB5C6A7, 0xE5E8DC], // moss
        [0x243B4A, 0x618A9C, 0xB0CAD0, 0xE7E8DD], // tidal slate
        [0x4A393C, 0x9F7973, 0xD0B0A2, 0xEEE3D8], // dusk
        [0x343B46, 0x7D8895, 0xBDC3C5, 0xE5E8E5]  // silver
    ]
    private static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255)
    }
}
