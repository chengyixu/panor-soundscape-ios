import SwiftUI
import UIKit

/// A single brand-consistent identity for any recording or creator without a
/// supplied image. FNV-backed variants are stable across launches and devices.
struct SoundscapeAvatar: View {
    let seed: String
    let size: CGFloat
    var photo: Data? = nil

    private var variant: Int { ProfileAvatar.generatedIndex(for: seed) }

    private var ground: Color {
        let shades: [Color] = [
            Color(red: 0.32, green: 0.35, blue: 0.34),
            Color(red: 0.39, green: 0.37, blue: 0.35),
            Color(red: 0.29, green: 0.32, blue: 0.35),
            Color(red: 0.44, green: 0.43, blue: 0.39),
            Color(red: 0.35, green: 0.37, blue: 0.32),
            Color(red: 0.40, green: 0.39, blue: 0.41),
            Color(red: 0.30, green: 0.31, blue: 0.30),
            Color(red: 0.42, green: 0.40, blue: 0.36)
        ]
        return shades[variant % shades.count]
    }

    var body: some View {
        ZStack {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else {
                generatedPattern
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(SoundscapeTheme.line.opacity(0.45), lineWidth: 0.5) }
        .accessibilityHidden(true)
    }

    private var generatedPattern: some View {
        Canvas { context, dimensions in
            let width = dimensions.width
            let height = dimensions.height
            let stroke = max(1, width * 0.026)
            for line in 0..<4 {
                let shift = CGFloat(line) * height * 0.19
                var path = Path()
                path.move(to: CGPoint(x: -width * 0.15, y: height * 0.74 - shift))
                path.addCurve(
                    to: CGPoint(x: width * 1.15, y: height * 0.58 - shift),
                    control1: CGPoint(x: width * (0.22 + CGFloat(variant % 3) * 0.06), y: height * (0.15 + CGFloat(line) * 0.13 + CGFloat(variant / 8) * 0.02)),
                    control2: CGPoint(x: width * (0.66 + CGFloat(variant % 2) * 0.07), y: height * (0.99 - CGFloat(line) * 0.12 - CGFloat(variant / 8) * 0.025))
                )
                context.stroke(path, with: .color(.white.opacity(line == 1 ? 0.88 : 0.46)), lineWidth: stroke)
            }
            let point = CGRect(x: width * (0.33 + CGFloat(variant % 4) * 0.09), y: height * 0.32, width: stroke * 2.6, height: stroke * 2.6)
            context.fill(Path(ellipseIn: point), with: .color(.white.opacity(0.9)))
        }
        .frame(width: size, height: size)
        .background(ground)
    }
}
