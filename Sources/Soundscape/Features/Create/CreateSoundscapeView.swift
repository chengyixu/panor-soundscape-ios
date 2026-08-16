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
                if isActive { await model.prepare() }
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
        VStack(spacing: 24) {
            Text(model.prompt)
                .font(.title3.weight(.semibold))
                .foregroundStyle(SoundscapeTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .soundscapeSurface()

            ZStack {
                Circle().fill(SoundscapeTheme.paperRaised.opacity(0.72)).frame(width: 236, height: 236)
                Circle().stroke(SoundscapeTheme.line.opacity(0.45), lineWidth: 1).frame(width: 236, height: 236)
                Circle().stroke(SoundscapeTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 10, dash: [2, 7])).frame(width: 190, height: 190)
                Button {
                    Task {
                        if case .recording = model.phase { await model.stopRecording() }
                        else { await model.startRecording() }
                    }
                } label: {
                    Image(systemName: recordingIcon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(SoundscapeTheme.paperRaised)
                        .frame(width: 92, height: 92)
                        .background(SoundscapeTheme.accent)
                        .clipShape(Circle())
                        .overlay { Circle().stroke(.white.opacity(0.2), lineWidth: 1) }
                }
                .disabled(model.phase == .requestingPermission)
                .sensoryFeedback(.impact, trigger: model.phase)
            }

            SoundscapeStatusLabel(title: recordingStatus, systemImage: recordingIcon)
            if case .recording(let startedAt) = model.phase {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(Self.durationText(from: startedAt, to: context.date))
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(SoundscapeTheme.ink)
                        .accessibilityLabel("\(loc(.createRecordingDuration)) \(Self.durationText(from: startedAt, to: context.date))")
                }
            }
            Button(loc(.createImportAudio)) { showsAudioImporter = true }.buttonStyle(SecondaryActionStyle())
        }
        .frame(maxWidth: .infinity)
    }

    private var reviewForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            section(loc(.createLocationSection)) {
                HStack {
                    Text(locationText)
                        .font(.subheadline)
                        .foregroundStyle(model.locationStatus == .available ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                    Spacer()
                    if model.locationStatus == .locating { ProgressView() }
                }
            }
            section(loc(.createTitleAndDescription)) {
                SoundscapeField(title: loc(.createTitleField)) {
                    TextField(loc(.createTitlePlaceholder), text: $model.title)
                        .textFieldStyle(.plain)
                }
                SoundscapeField(title: loc(.createDescriptionField)) {
                    TextField(loc(.createDescriptionPlaceholder), text: $model.description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                }
                if model.phase == .generatingTitle {
                    Label(loc(.createThinkingGeneratingTitle), systemImage: "sparkles")
                        .font(.footnote)
                        .foregroundStyle(SoundscapeTheme.accent)
                }
            }
            .disabled(model.phase == .generatingTitle)
            section(loc(.createCoverSection)) {
                HStack(spacing: 14) {
                    coverPreview
                    VStack(alignment: .leading, spacing: 10) {
                        if model.phase == .generatingCover {
                            Label(loc(.createAIGeneratingCover), systemImage: "wand.and.stars")
                                .font(.footnote)
                                .foregroundStyle(SoundscapeTheme.accent)
                        } else {
                            Text(loc(.createAICoverHint))
                                .font(.footnote)
                                .foregroundStyle(SoundscapeTheme.secondaryInk)
                        }
                        PhotosPicker(selection: $coverItem, matching: .images) {
                            Label(loc(.createChooseFromLibrary), systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(SecondaryActionStyle())
                        .disabled(model.isGeneratingMetadata)
                    }
                }
            }
            if let generationError = model.generationError {
                VStack(alignment: .leading, spacing: 10) {
                    Text(generationError.userMessage)
                        .font(.footnote)
                        .foregroundStyle(SoundscapeTheme.accent)
                    Button(loc(.createRegenerate)) { Task { await model.enrichAutomatically() } }
                        .buttonStyle(SecondaryActionStyle())
                }
            }
            section(loc(.createCategoryAndFeel)) {
                Picker(loc(.createCategoryLabel), selection: $model.category) {
                    ForEach(SoundscapeCategory.creationCases, id: \.rawValue) { category in
                        Text(category.localizedTitle).tag(category.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                Slider(value: $model.personalSocial, in: 0...1) { Text(loc(.createPersonalToSocial)) } minimumValueLabel: { Text(loc(.createPersonal)) } maximumValueLabel: { Text(loc(.createSocial)) }
                Slider(value: $model.memoryPresent, in: 0...1) { Text(loc(.createMemoryToPresent)) } minimumValueLabel: { Text(loc(.createMemory)) } maximumValueLabel: { Text(loc(.createPresent)) }
                Toggle(loc(.createPublicToggle), isOn: $model.isPublic).tint(SoundscapeTheme.accent)
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
            RemoteCover(url: soundscape.coverURL, category: soundscape.category)
                .frame(height: 310)
                .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.featureRadius, style: .continuous))
            SoundscapeStatusLabel(title: loc(.createPublished), systemImage: "checkmark.circle.fill")
            Text(soundscape.displayTitle).font(SoundscapeTheme.featureTitleFont)
            Text(soundscape.locationDisplay).foregroundStyle(SoundscapeTheme.secondaryInk)
            Button(loc(.createRecordAnother)) { Task { await model.reset() } }.buttonStyle(PrimaryActionStyle())
        }
        .padding(18)
        .soundscapeSurface(cornerRadius: SoundscapeTheme.featureRadius)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SoundscapeSectionHeader(title: title)
            content()
        }
        .padding(18)
        .soundscapeSurface()
    }

    @ViewBuilder private var coverPreview: some View {
        if let file = model.uploadedCover, let image = UIImage(data: file.data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 112, height: 112).clipShape(RoundedRectangle(cornerRadius: 18))
        } else if let path = model.generatedCoverPath {
            RemoteCover(url: APIEnvironment.production.mediaURL(for: path), category: model.category, isAI: true)
                .frame(width: 112, height: 112).clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(alignment: .bottomTrailing) {
                    Text(loc(.coverAIBadge)).font(.caption2.bold()).padding(6).background(.ultraThinMaterial).clipShape(Capsule()).padding(6)
                }
        } else {
            RoundedRectangle(cornerRadius: 18).fill(SoundscapeTheme.line.opacity(0.18)).frame(width: 112, height: 112)
                .overlay {
                    if model.phase == .generatingCover {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text(loc(.createThinking)).font(.caption)
                        }
                    } else {
                        Image(systemName: "photo").foregroundStyle(SoundscapeTheme.secondaryInk)
                    }
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
