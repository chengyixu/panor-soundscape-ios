import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct CreateSoundscapeView: View {
    @Environment(LocaleManager.self) private var localeManager
    @State private var model: CreateSoundscapeViewModel
    let session: IdentitySession
    let isActive: Bool
    @State private var coverItem: PhotosPickerItem?
    @State private var showsAudioImporter = false
    @State private var showsIdentity = false
    @State private var localError: AppError?
    @State private var showsMoreOptions = false

    init(
        repository: any SoundscapeRepository,
        recorder: any RecordingService,
        location: any LocationProviding,
        session: IdentitySession,
        isActive: Bool
    ) {
        _model = State(initialValue: CreateSoundscapeViewModel(repository: repository, recorder: recorder, location: location))
        self.session = session
        self.isActive = isActive
    }

    var body: some View {
        let locale = localeManager.current

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(title: loc(.createTitle))
                    phaseContent
                }
                .padding(SoundscapeTheme.screenPadding)
                .padding(.bottom, 40)
            }
            .soundscapeScreenBackground()
            .sheet(isPresented: $showsIdentity) { IdentitySheet(session: session) }
            .fileImporter(isPresented: $showsAudioImporter, allowedContentTypes: [.audio]) { result in
                Task { await handleImportedAudio(result) }
            }
            .onChange(of: coverItem) { _, item in
                guard let item else { return }
                Task { await loadCover(item) }
            }
            .task(id: isActive) {
                guard isActive else { return }
#if DEBUG
                if ProcessInfo.processInfo.environment["SOUNDSCAPE_UI_TEST_SHARE_DRAFT"] == "1",
                   let file = Bundle.main.url(forResource: "AutoplayTestTone", withExtension: "m4a"),
                   let data = try? Data(contentsOf: file) {
                    await model.useImportedAudio(data: data, filename: "Rain at the Pier.wav", contentType: "audio/mp4")
                }
#endif
                await model.prepare()
            }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    @ViewBuilder private var phaseContent: some View {
        switch model.phase {
        case .idle, .requestingPermission, .recording:
            capturePanel
        case .review, .generatingTitle, .generatingCover, .publishing:
            reviewForm
        case .published(let soundscape):
            published(soundscape)
        case .failed(let error):
            VStack(spacing: 16) {
                ErrorStateView(error: error, retry: model.recover)
                Button(loc(.createRecordAnother)) { Task { await model.reset() } }.buttonStyle(SecondaryActionStyle())
            }
        }
        if let localError {
            Label(localError.userMessage, systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(SoundscapeTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .soundscapeSurface(cornerRadius: SoundscapeTheme.controlRadius, shadow: false)
        }
    }

    private var capturePanel: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(model.prompt)
                .font(.title2.weight(.semibold))
                .tracking(-0.45)
                .foregroundStyle(SoundscapeTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                VinylRecordArtwork(isRotating: isRecording)
                    .frame(width: 240, height: 240)
                    .accessibilityHidden(true)
                Button {
                    Task {
                        if case .recording = model.phase { await model.stopRecording() }
                        else { await model.startRecording() }
                    }
                } label: {
                    Image(systemName: recordingIcon)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(SoundscapeTheme.ink)
                        .frame(width: 68, height: 68)
                        .background(SoundscapeTheme.paperRaised, in: Circle())
                }
                .accessibilityLabel(recordingStatus)
                .accessibilityIdentifier("share-record-control")
                .disabled(model.phase == .requestingPermission)
                .sensoryFeedback(.impact, trigger: model.phase)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                SoundscapeStatusLabel(title: recordingStatus, systemImage: recordingIcon)
                Spacer()
                if case .recording(let startedAt) = model.phase {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(Self.durationText(from: startedAt, to: context.date))
                            .font(.title2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(SoundscapeTheme.ink)
                            .accessibilityLabel("\(loc(.createRecordingDuration)) \(Self.durationText(from: startedAt, to: context.date))")
                    }
                }
            }
            Divider()
            Button(loc(.createImportAudio)) { showsAudioImporter = true }
                .buttonStyle(SecondaryActionStyle())
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewForm: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                coverPreview
                VStack(alignment: .leading, spacing: 9) {
                    Text(loc(.createTitleAndDescription))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(SoundscapeTheme.ink)
                    Label(locationText, systemImage: "location")
                        .font(.subheadline)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                        .lineLimit(2)
                    Text(loc(.createArtworkOptional))
                        .font(.caption)
                        .foregroundStyle(SoundscapeTheme.secondaryInk)
                }
            }
            SoundscapeField(title: loc(.createTitleField)) {
                TextField(loc(.createTitlePlaceholder), text: $model.title)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("share-title")
            }
            SoundscapeField(title: loc(.createDescriptionField)) {
                TextField(loc(.createDescriptionPlaceholder), text: $model.description, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(2...4)
                    .accessibilityIdentifier("share-description")
            }
            HStack(alignment: .top, spacing: 8) {
                Button {
                    Task { await model.suggestTitle() }
                } label: {
                    ShareActionTile(title: loc(model.phase == .generatingTitle ? .createThinking : .createSuggestTitle), symbol: "sparkles")
                }
                .accessibilityIdentifier("share-action-title")
                .disabled(model.isGeneratingMetadata || model.phase == .publishing)

                PhotosPicker(selection: $coverItem, matching: .images) {
                    ShareActionTile(title: loc(.createChooseFromLibrary), symbol: "photo")
                }
                .accessibilityIdentifier("share-action-photo")
                .disabled(model.isGeneratingMetadata || model.phase == .publishing)

                Button {
                    Task { await model.suggestCover() }
                } label: {
                    ShareActionTile(title: loc(model.phase == .generatingCover ? .createThinking : .createSuggestCover), symbol: "wand.and.stars")
                }
                .accessibilityIdentifier("share-action-artwork")
                .disabled(model.isGeneratingMetadata || model.phase == .publishing)
            }
            .buttonStyle(.plain)
            if model.generationError != nil {
                Text(loc(.createSuggestionUnavailable))
                    .font(.footnote)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            DisclosureGroup(loc(.createCategoryAndFeel), isExpanded: $showsMoreOptions) {
                VStack(spacing: 18) {
                    Picker(loc(.createCategoryLabel), selection: $model.category) {
                        ForEach(SoundscapeCategory.creationCases, id: \.rawValue) { category in
                            Text(category.localizedTitle).tag(category.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Slider(value: $model.personalSocial, in: 0...1) { Text(loc(.createPersonalToSocial)) }
                        minimumValueLabel: { Text(loc(.createPersonal)) }
                        maximumValueLabel: { Text(loc(.createSocial)) }
                    Slider(value: $model.memoryPresent, in: 0...1) { Text(loc(.createMemoryToPresent)) }
                        minimumValueLabel: { Text(loc(.createMemory)) }
                        maximumValueLabel: { Text(loc(.createPresent)) }
                }
                .padding(.top, 12)
            }
            .tint(SoundscapeTheme.ink)
            Divider()
            Toggle(loc(.createPublicToggle), isOn: $model.isPublic)
                .tint(SoundscapeTheme.accent)
            if model.isPublic {
                Text(loc(.moderationAwaitingApproval))
                    .font(.footnote)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
            }
            if session.user == nil {
                Button(loc(.createLoginToPublish)) { showsIdentity = true }.buttonStyle(PrimaryActionStyle())
            } else {
                Button {
                    Task { await model.publish() }
                } label: {
                    HStack {
                        if model.phase == .publishing { ProgressView().tint(SoundscapeTheme.paperRaised) }
                        Text(model.phase == .publishing ? loc(.createPublishing) : loc(.createPublishSoundscape))
                    }
                }
                .buttonStyle(PrimaryActionStyle())
                .disabled(!model.canPublish || model.phase == .publishing)
            }
        }
    }

    private func published(_ soundscape: Soundscape) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Group {
                if soundscape.moderationStatus == "pending", let data = model.stagedCoverData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    RemoteCover(url: soundscape.coverURL, category: soundscape.category, avatarSeed: soundscape.id)
                }
            }
                .frame(height: 310)
                .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.featureRadius, style: .continuous))
            SoundscapeStatusLabel(title: soundscape.moderationStatus == "pending" ? loc(.moderationAwaitingApproval) : loc(.createPublished), systemImage: "checkmark.circle.fill")
            Text(soundscape.displayTitle).font(SoundscapeTheme.featureTitleFont)
            Text(soundscape.locationDisplay).foregroundStyle(SoundscapeTheme.secondaryInk)
            Button(loc(.createRecordAnother)) { Task { await model.reset() } }.buttonStyle(PrimaryActionStyle())
        }
        .padding(18)
        .soundscapeSurface(cornerRadius: SoundscapeTheme.featureRadius)
    }

    @ViewBuilder private var coverPreview: some View {
        if let file = model.uploadedCover, let image = UIImage(data: file.data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 112, height: 112).clipShape(RoundedRectangle(cornerRadius: 18))
        } else if model.generatedCoverPath != nil, let data = model.stagedCoverData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: 112, height: 112).clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(alignment: .bottomTrailing) {
                    Text(loc(.coverAIBadge)).font(.caption2.bold()).padding(6).background(.ultraThinMaterial).clipShape(Capsule()).padding(6)
                }
        } else {
            SoundscapeAvatar(seed: session.user?.id ?? "guest", size: 112)
                .overlay {
                    if model.phase == .generatingCover { ProgressView().tint(.white) }
                }
        }
    }

    private var locationText: String {
        switch model.locationStatus {
        case .idle, .locating: loc(.createLocating)
        case .available: model.place?.name ?? loc(.createCurrentLocation)
        case .unavailable: loc(.createNoLocationPermission)
        }
    }

    private var isRecording: Bool {
        if case .recording = model.phase { return true }
        return false
    }

    private var recordingIcon: String {
        if case .recording = model.phase { return "stop.fill" }
        return "mic.fill"
    }

    private var recordingStatus: String {
        switch model.phase {
        case .recording: loc(.createRecordingState)
        case .requestingPermission: loc(.createRequestingPermission)
        default: loc(.createReadyToRecord)
        }
    }

    private func loadCover(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                localError = .invalidRequest(loc(.createCannotReadCover))
                return
            }
            let normalized = try CoverImageProcessor.normalizedJPEG(from: data)
            model.useUploadedCover(data: normalized)
            localError = nil
        } catch let appError as AppError {
            localError = appError
        } catch {
            localError = .invalidRequest(loc(.createCannotReadCover))
        }
    }

    private func handleImportedAudio(_ result: Result<URL, Error>) async {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile != false else { throw AppError.invalidRequest(loc(.createSelectAudioFile)) }
            if let byteCount = values.fileSize { try MediaConstraints.validateAudioByteCount(byteCount) }
            let data = try Data(contentsOf: url)
            let type = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            await model.useImportedAudio(data: data, filename: url.lastPathComponent, contentType: type)
            localError = nil
        } catch let appError as AppError {
            localError = appError
        } catch {
            localError = .invalidRequest(loc(.createCannotReadAudio))
        }
    }

    private static func durationText(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ShareActionTile: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(SoundscapeTheme.ink)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 76)
        .padding(.horizontal, 3)
        .background(SoundscapeTheme.paperRaised, in: RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius))
        .overlay {
            RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius)
                .strokeBorder(SoundscapeTheme.line.opacity(0.75), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}
