import SwiftUI

struct SoundscapeScreenBackground: View {
    var body: some View {
        SoundscapeTheme.paper
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct SoundscapeSectionHeader: View {
    let title: String
    var detail: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SoundscapeTheme.ink)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct SoundscapeStatusLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(SoundscapeTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                SoundscapeTheme.paperRaised,
                in: RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius, style: .continuous)
                    .stroke(SoundscapeTheme.line, lineWidth: 1)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

struct SoundscapeTag: View {
    let title: String
    var selected = false
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(title, action: action)
            } else {
                Text(title)
            }
        }
        .font(.subheadline.weight(selected ? .semibold : .regular))
        .foregroundStyle(selected ? SoundscapeTheme.paperRaised : SoundscapeTheme.secondaryInk)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(selected ? SoundscapeTheme.ink : SoundscapeTheme.paperRaised, in: Capsule())
        .overlay {
            if !selected {
                Capsule().stroke(SoundscapeTheme.line.opacity(0.65), lineWidth: 1)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

struct SoundscapeField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoundscapeTheme.secondaryInk)
            content
                .font(.body)
                .foregroundStyle(SoundscapeTheme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .soundscapeSurface(cornerRadius: SoundscapeTheme.controlRadius, shadow: false)
    }
}

private struct SoundscapeSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            .background(
                SoundscapeTheme.paperRaised,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(SoundscapeTheme.line.opacity(shadow ? 0.75 : 0.55), lineWidth: 0.75)
            }
    }
}

extension View {
    func soundscapeScreenBackground() -> some View {
        background { SoundscapeScreenBackground() }
    }

    func soundscapeSurface(
        cornerRadius: CGFloat = SoundscapeTheme.cardRadius,
        shadow: Bool = true
    ) -> some View {
        modifier(SoundscapeSurfaceModifier(cornerRadius: cornerRadius, shadow: shadow))
    }
}
