import SwiftUI

struct ForYouView: View {
    @Environment(LocaleManager.self) private var localeManager

    enum ComposerMode {
        case open
        case guided
    }

    enum RecordingPhase: Equatable {
        case idle
        case requestingPermission
        case recording(Date)
    }

    let matching: any ResonanceMatching
    let intentParser: any ResonanceIntentParsing
    let recorder: any RecordingService
    let player: AudioPlayerController

    @AppStorage("soundscape.for-you.private-draft") private var draftText = ""
    @AppStorage("soundscape.for-you.microphone-explained") private var microphoneExplained = false
    @State private var composerMode: ComposerMode = .open
    @State private var guidedAnswer = ""
    @State private var recordingPhase: RecordingPhase = .idle
    @State private var isShaping = false
    @State private var error: AppError?
    @State private var showsMicrophoneSheet = false
    @State private var hasRecordedInput = false

    var body: some View {
        let locale = localeManager.current

        composer
        .sheet(isPresented: $showsMicrophoneSheet) { microphoneSheet }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private var composer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(
                    eyebrow: loc(.forYouEyebrow),
                    title: loc(.forYouTitle),
                    detail: loc(.forYouDetail)
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        SoundscapeStatusLabel(title: loc(.forYouPrivateByDefault), systemImage: "lock.fill")
                        SoundscapeStatusLabel(title: loc(.forYouAnySound), systemImage: "waveform")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SoundscapeStatusLabel(title: loc(.forYouPrivateByDefault), systemImage: "lock.fill")
                        SoundscapeStatusLabel(title: loc(.forYouAnySound), systemImage: "waveform")
                    }
                }
                .accessibilityElement(children: .contain)

                if composerMode == .guided {
                    guidedComposer
                } else {
                    openComposer
                }

                if isShaping {
                    SoundscapeStatusLabel(title: loc(.forYouListeningShaping), systemImage: "waveform.path.ecg")
                        .accessibilityIdentifier("for-you-shaping")
                }

                if let error {
                    ErrorStateView(error: error) {
                        Task { await makeSoundscape() }
                    }
                }
            }
            .padding(SoundscapeTheme.screenPadding)
            .padding(.bottom, 40)
        }
        .soundscapeScreenBackground()
    }

    private var openComposer: some View {
        VStack(spacing: 16) {
            TextEditor(text: $draftText)
                .frame(minHeight: 190)
                .padding(14)
                .scrollContentBackground(.hidden)
                .soundscapeSurface(cornerRadius: SoundscapeTheme.featureRadius)
                .overlay(alignment: .topLeading) {
                    if draftText.isEmpty {
                        Text(loc(.forYouAnythingPlaceholder))
                            .foregroundStyle(SoundscapeTheme.secondaryInk.opacity(0.72))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel(loc(.forYouPrivateInput))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    recordButton
                    guideButton
                }
                VStack(spacing: 12) {
                    recordButton
                    guideButton
                }
            }

            if case .recording(let startedAt) = recordingPhase {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack {
                        Circle().fill(SoundscapeTheme.accent).frame(width: 8, height: 8)
                        Text(recordingDuration(from: startedAt, to: context.date))
                            .font(.title2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(SoundscapeTheme.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .soundscapeSurface(cornerRadius: SoundscapeTheme.controlRadius, shadow: false)
                }
            }

            Button(loc(.forYouMakeSoundscape)) {
                Task { await makeSoundscape() }
            }
            .buttonStyle(PrimaryActionStyle())
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isShaping)
        }
    }

    private var recordButton: some View {
        Button {
            handleRecordTap()
        } label: {
            Label(recordingLabel, systemImage: recordingIcon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryActionStyle())
        .disabled(recordingPhase == .requestingPermission || isShaping)
    }

    private var guideButton: some View {
        Button {
            composerMode = .guided
        } label: {
            Text(loc(.forYouGuideMe))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryActionStyle())
        .disabled(isShaping)
    }

    private var guidedComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                composerMode = .open
            } label: {
                Label(loc(.generalBack), systemImage: "chevron.left")
            }
            .buttonStyle(SecondaryActionStyle())

            Text(loc(.forYouGuidedQuestion))
                .font(.title2.bold())
                .foregroundStyle(SoundscapeTheme.ink)

            TextField(loc(.forYouGuidedPlaceholder), text: $guidedAnswer, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(16)
                .soundscapeSurface(cornerRadius: SoundscapeTheme.controlRadius, shadow: false)

            Button(loc(.forYouMakeNow)) {
                draftText = guidedAnswer
                Task { await makeSoundscape() }
            }
            .buttonStyle(PrimaryActionStyle())
            .disabled(guidedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isShaping)
        }
        .padding(20)
        .soundscapeSurface(cornerRadius: SoundscapeTheme.featureRadius)
    }

    private var microphoneSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "mic.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(SoundscapeTheme.accent)
            Text(loc(.forYouMicrophoneTitle))
                .font(.title2.bold())
            Text(loc(.forYouMicrophoneDetail))
                .foregroundStyle(SoundscapeTheme.secondaryInk)
            Button(loc(.generalContinue)) {
                microphoneExplained = true
                showsMicrophoneSheet = false
                Task { await startRecording() }
            }
            .buttonStyle(PrimaryActionStyle())
            Button(loc(.generalNotNow)) { showsMicrophoneSheet = false }
                .buttonStyle(SecondaryActionStyle())
        }
        .padding(24)
        .soundscapeScreenBackground()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var recordingLabel: String {
        if case .recording = recordingPhase { return loc(.forYouStop) }
        return loc(.forYouRecord)
    }

    private var recordingIcon: String {
        if case .recording = recordingPhase { return "stop.fill" }
        return "mic.fill"
    }

    private func handleRecordTap() {
        if case .recording = recordingPhase {
            Task { await stopRecording() }
        } else if microphoneExplained {
            Task { await startRecording() }
        } else {
            showsMicrophoneSheet = true
        }
    }

    private func startRecording() async {
        player.pause()
        recordingPhase = .requestingPermission
        do {
            try await recorder.start()
            recordingPhase = .recording(Date())
        } catch let appError as AppError {
            recordingPhase = .idle
            self.error = appError
        } catch {
            recordingPhase = .idle
            self.error = .recordingUnavailable
        }
    }

    private func stopRecording() async {
        do {
            _ = try await recorder.stop()
            recordingPhase = .idle
            hasRecordedInput = true
            await makeSoundscape()
        } catch let appError as AppError {
            recordingPhase = .idle
            self.error = appError
        } catch {
            recordingPhase = .idle
            self.error = .recordingUnavailable
        }
    }

    private func makeSoundscape() async {
        guard !isShaping else { return }
        isShaping = true
        error = nil
        do {
            let normalizedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
            var provenance: Set<ResonanceInputProvenance> = []
            if !normalizedText.isEmpty { provenance.insert(composerMode == .guided ? .goal : .text) }
            if hasRecordedInput { provenance.insert(.recording) }
            let request = intentParser.request(
                from: ResonanceInput(text: normalizedText, provenance: provenance),
                now: Date()
            )
            let batch = try await matching.recommendations(for: request)
            draftText = ""
            guidedAnswer = ""
            composerMode = .open
            hasRecordedInput = false
            await player.openRecommendationBatch(batch)
        } catch let appError as AppError {
            self.error = appError
        } catch {
            self.error = .transport(String(describing: type(of: error)))
        }
        isShaping = false
    }

    private func recordingDuration(from start: Date, to end: Date) -> String {
        let seconds = max(0, min(300, Int(end.timeIntervalSince(start))))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
