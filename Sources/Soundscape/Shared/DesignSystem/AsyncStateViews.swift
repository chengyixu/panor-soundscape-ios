import SwiftUI

struct SoundscapeLoadingState: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(title)
                .font(.caption)
                .foregroundStyle(SoundscapeTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 72)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(SoundscapeTheme.ink)
            Text(title).font(.title3.bold()).foregroundStyle(SoundscapeTheme.ink)
            Text(detail).font(.subheadline).foregroundStyle(SoundscapeTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .soundscapeSurface()
    }
}

struct ErrorStateView: View {
    @Environment(LocaleManager.self) private var localeManager
    let error: AppError
    let retry: () -> Void

    var body: some View {
        let locale = localeManager.current

        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(SoundscapeTheme.ink)
            Text(loc(.exploreLoadingFailed)).font(.title3.bold())
            Text(error.userMessage).font(.subheadline).foregroundStyle(SoundscapeTheme.secondaryInk)
            Button(loc(.generalRetry), action: retry).buttonStyle(SecondaryActionStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .soundscapeSurface()
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }
}
