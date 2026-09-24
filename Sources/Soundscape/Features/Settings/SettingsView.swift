import SwiftUI

struct SettingsView: View {
    let recorder: any RecordingService
    let player: AudioPlayerController
    let matching: any ResonanceMatching
    let intentParser: any ResonanceIntentParsing
    @State private var showsForYou = false
    @State private var showsResetConfirmation = false
    @State private var showsResetComplete = false
    @State private var resetError: AppError?
    @Environment(\.dismiss) private var dismiss
    @Environment(LocaleManager.self) private var localeManager

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section(localeManager.string(.settingsSectionGeneral)) {
                    languagePicker
                    HStack {
                        Label(localeManager.string(.settingsAppVersion), systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(SoundscapeTheme.secondaryInk)
                            .font(.subheadline.monospacedDigit())
                    }
                }

                Section(localeManager.string(.settingsSectionPrivacy)) {
                    NavigationLink { privacyPolicy } label: {
                        Label(localeManager.string(.settingsPrivacyPolicy), systemImage: "hand.raised")
                    }
                    NavigationLink { termsOfService } label: {
                        Label(localeManager.string(.settingsTermsOfService), systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "mailto:support@panor.tech")!) {
                        Label(localeManager.string(.moderationContact), systemImage: "envelope")
                    }
                    .accessibilityIdentifier("contact-support")
                }

                Section(localeManager.string(.settingsSectionForYou)) {
                    Button {
                        showsForYou = true
                    } label: {
                        Label(localeManager.string(.libraryForYou), systemImage: "sparkles")
                    }
                    .accessibilityIdentifier("settings-for-you")
                    Button(role: .destructive) {
                        showsResetConfirmation = true
                    } label: {
                        Label(localeManager.string(.settingsResetRecommendations), systemImage: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("settings-reset-recommendations")
                }
            }
            .navigationTitle(localeManager.string(.settingsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localeManager.string(.libraryClose)) { dismiss() }
                        .accessibilityIdentifier("close-settings")
                }
            }
            .fullScreenCover(isPresented: $showsForYou) {
                NavigationStack {
                    ForYouView(
                        matching: matching,
                        intentParser: intentParser,
                        recorder: recorder,
                        player: player
                    )
                        .navigationTitle(localeManager.string(.libraryForYou))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(localeManager.string(.libraryClose)) { showsForYou = false }
                                    .accessibilityIdentifier("close-for-you")
                            }
                        }
                    }
                }
            .confirmationDialog(
                localeManager.string(.settingsResetRecommendationsConfirm),
                isPresented: $showsResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(localeManager.string(.settingsResetRecommendations), role: .destructive) {
                    Task { await resetRecommendations() }
                }
                Button(localeManager.string(.generalCancel), role: .cancel) {}
            }
            .alert(localeManager.string(.settingsResetRecommendationsDone), isPresented: $showsResetComplete) {
                Button(localeManager.string(.generalOK)) {}
            }
            .alert(localeManager.string(.errorGeneric), isPresented: resetErrorBinding) {
                Button(localeManager.string(.generalOK)) { resetError = nil }
            } message: {
                Text(resetError?.userMessage ?? localeManager.string(.errorTryAgain))
            }
        }
    }

    private func resetRecommendations() async {
        do {
            try await matching.resetPersonalization()
            player.clearRecommendationPersonalization()
            showsResetComplete = true
        } catch let appError as AppError {
            resetError = appError
        } catch {
            resetError = .personalizationUnavailable
        }
    }

    private var resetErrorBinding: Binding<Bool> {
        Binding(
            get: { resetError != nil },
            set: { if !$0 { resetError = nil } }
        )
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localeManager.string(.settingsLanguage), systemImage: "globe")
                .font(.body)
                .foregroundStyle(SoundscapeTheme.ink)
            HStack(spacing: 10) {
                ForEach(AppLocale.allCases, id: \.rawValue) { locale in
                    Button {
                        localeManager.current = locale
                    } label: {
                        Text(locale.displayName)
                            .font(.subheadline.weight(localeManager.current == locale ? .semibold : .regular))
                            .foregroundStyle(localeManager.current == locale ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(localeManager.current == locale ? SoundscapeTheme.ink.opacity(0.08) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(localeManager.current == locale ? SoundscapeTheme.ink.opacity(0.3) : SoundscapeTheme.line.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings-language-\(locale.rawValue)")
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var privacyPolicy: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(localeManager.string(.settingsPrivacyPolicy)).font(.title.bold())
                Text(localeManager.string(.settingsPrivacyBody))
                .font(.body).foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            .padding(SoundscapeTheme.screenPadding)
        }
        .navigationTitle(loc(.settingsPrivacyPolicy))
        .soundscapeScreenBackground()
    }

    private var termsOfService: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(localeManager.string(.settingsTermsOfService)).font(.title.bold())
                Text(localeManager.string(.settingsTermsBody))
                .font(.body).foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            .padding(SoundscapeTheme.screenPadding)
        }
        .navigationTitle(loc(.settingsTermsOfService))
        .soundscapeScreenBackground()
    }
}
