import Foundation

/// Native adaptation of Boring Avatars Marble (MIT, copyright 2021 boringdesigners).
/// Pinned source and license: Resources/Licenses/BoringAvatars.txt.
/// Recipe version 2: full-seed geometry, never a random redraw or 32-item index.
struct MarbleAvatarRecipe: Hashable, Sendable {
    struct Layer: Hashable, Sendable {
        let color: Int
        let x: Double
        let y: Double
        let scale: Double
        let rotation: Double
    }
    let palette: Int
    let layers: [Layer]

    init(seed: String) {
        var hash: Int32 = 0
        for unit in seed.utf16 { hash = (hash &* 31) &+ Int32(unit) }
        let number = abs(Int64(hash))
        palette = Int((number / 7) % 4)
        layers = (0..<3).map { index in
            let n = number * Int64(index + 1)
            return Layer(color: Int((number + Int64(index)) % 4),
                         x: Self.unit(n, range: 8, digit: 1),
                         y: Self.unit(n, range: 8, digit: 2),
                         scale: 1.2 + Double(n % 4) / 10,
                         rotation: Self.unit(n, range: 360, digit: 1))
        }
    }

    private static func unit(_ number: Int64, range: Int64, digit: Int) -> Double {
        let position: Int64 = digit == 1 ? 10 : 100
        return Double(number % range) * (((number / position) % 10).isMultiple(of: 2) ? -1 : 1)
    }
}
