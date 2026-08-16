import SwiftUI

enum SoundscapeTheme {
    static let paper = Color(red: 0.985, green: 0.985, blue: 0.98)
    static let paperRaised = Color.white
    static let paperDeep = Color(red: 0.94, green: 0.94, blue: 0.93)
    static let ink = Color(red: 0.035, green: 0.035, blue: 0.035)
    static let secondaryInk = Color(red: 0.36, green: 0.36, blue: 0.35)
    static let tertiaryInk = Color(red: 0.56, green: 0.56, blue: 0.54)
    static let accent = ink
    static let accentSoft = Color(red: 0.82, green: 0.82, blue: 0.8)
    static let line = Color(red: 0.82, green: 0.82, blue: 0.8)
    static let playerBackground = Color(red: 0.025, green: 0.025, blue: 0.025)
    static let playerInk = Color.white
    static let playerSecondaryInk = Color.white.opacity(0.62)
    static let playerLine = Color.white.opacity(0.18)

    static let screenPadding: CGFloat = 20
    static let compactRadius: CGFloat = 8
    static let controlRadius: CGFloat = 12
    static let cardRadius: CGFloat = 16
    static let featureRadius: CGFloat = 18

    static let surfaceShadow = Color.clear
    static let strongShadow = ink.opacity(0.08)

    static let screenTitleFont = Font.system(size: 34, weight: .bold, design: .default)
    static let featureTitleFont = Font.system(size: 26, weight: .semibold, design: .default)

    static func categoryTint(_ category: String) -> Color {
        switch SoundscapeCategory(rawValue: category) {
        case .nature, .natureParks: Color(red: 0.38, green: 0.4, blue: 0.37)
        case .architecture: Color(red: 0.27, green: 0.29, blue: 0.31)
        default: Color(red: 0.44, green: 0.43, blue: 0.4)
        }
    }
}

struct ScreenHeader: View {
    let eyebrow: String?
    let title: String
    let detail: String?

    init(eyebrow: String? = nil, title: String, detail: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow, !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.25)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            Text(title)
                .font(SoundscapeTheme.screenTitleFont)
                .tracking(-1.05)
                .foregroundStyle(SoundscapeTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                    .lineSpacing(3)
                    .frame(maxWidth: 420, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(SoundscapeTheme.paperRaised)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 18)
            .background(SoundscapeTheme.ink)
            .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .animation(reduceMotion ? nil : .spring(response: 0.26, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct SecondaryActionStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(SoundscapeTheme.ink)
            .frame(minHeight: 48)
            .padding(.horizontal, 14)
            .background(.clear)
            .overlay {
                RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius, style: .continuous)
                    .stroke(SoundscapeTheme.ink.opacity(0.82), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct CircularActionStyle: ButtonStyle {
    let foreground: Color
    let background: Color
    var size: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background)
            .clipShape(Circle())
            .overlay { Circle().stroke(SoundscapeTheme.line.opacity(0.7), lineWidth: 1) }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}
