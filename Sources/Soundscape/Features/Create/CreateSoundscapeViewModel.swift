import Foundation
import Observation

@MainActor
@Observable
final class CreateSoundscapeViewModel {
    enum Phase: Equatable {
        case idle
        case requestingPermission
        case recording(startedAt: Date)
        case review
        case generatingTitle
        case generatingCover
        case publishing
        case published(Soundscape)
        case failed(AppError)
    }

    enum LocationStatus: Equatable {
        case idle
        case locating
        case available
        case unavailable
    }

    private(set) var phase: Phase = .idle
    private(set) var audio: MediaFile?
    private(set) var uploadedCover: MediaFile?
    private(set) var generatedCoverPath: String?
    private(set) var place: Place?
    private(set) var locationStatus: LocationStatus = .idle
    private(set) var generationError: AppError?

    var title = ""
    var description = ""
    var category = SoundscapeCategory.place.rawValue
    var prompt: String { loc(.createDefaultPrompt) }
    var personalSocial = 0.5
    var memoryPresent = 0.5
    var isPublic = true

    private let repository: any SoundscapeRepository
    private let recorder: any RecordingService
    private let location: any LocationProviding
    private var hasPrepared = false

    init(repository: any SoundscapeRepository, recorder: any RecordingService, location: any LocationProviding) {
        self.repository = repository
        self.recorder = recorder
        self.location = location
    }

    var hasCover: Bool { uploadedCover != nil || generatedCoverPath != nil }
    var canPublish: Bool { audio != nil && hasCover && DraftConstraints.titleIsValid(title) }
    var isGeneratingMetadata: Bool { phase == .generatingTitle || phase == .generatingCover }

    func prepare() async {
        guard !hasPrepared else { return }
        hasPrepared = true
        locationStatus = .locating
        do {
            place = try await location.currentPlace()
            locationStatus = .available
        } catch {
            place = nil
            locationStatus = .unavailable
        }
    }

    func startRecording() async {
        phase = .requestingPermission
        do {
            try await recorder.start()
            phase = .recording(startedAt: Date())
        } catch let error as AppError {
            phase = .failed(error)
        } catch {
            phase = .failed(.recordingUnavailable)
        }
    }

    func stopRecording() async {
        do {
            audio = try await recorder.stop()
            phase = .review
            await enrichAutomatically()
        } catch let error as AppError {
            phase = .failed(error)
        } catch {
            phase = .failed(.recordingUnavailable)
        }
    }

    func useImportedAudio(
        data: Data,
        filename: String,
        contentType: String,
        generateAutomatically: Bool = true
    ) async {
        do {
            audio = try MediaConstraints.audio(data: data, filename: filename, contentType: contentType)
            phase = .review
            if generateAutomatically { await enrichAutomatically() }
        } catch let error as AppError {
            phase = .failed(error)
        } catch {
            phase = .failed(.invalidRequest(loc(.createCannotReadAudio)))
        }
    }

    func useUploadedCover(data: Data) {
        do {
            uploadedCover = try MediaConstraints.cover(data: data)
            generatedCoverPath = nil
        } catch let error as AppError {
            phase = .failed(error)
        } catch {
            phase = .failed(.invalidRequest(loc(.createCannotReadCover)))
        }
    }

    func suggestTitle() async {
        phase = .generatingTitle
        do {
            let suggestion = try await repository.suggestTitle(titleRequest)
            title = suggestion.title
            description = suggestion.description
            generationError = nil
            phase = .review
        } catch let error as AppError {
            generationError = error
            phase = .review
        } catch {
            generationError = .transport(String(describing: type(of: error)))
            phase = .review
        }
    }

    func suggestCover() async {
        phase = .generatingCover
        do {
            let suggestion = try await repository.suggestCover(coverRequest)
            generatedCoverPath = suggestion.coverURL
            uploadedCover = nil
            generationError = nil
            phase = .review
        } catch let error as AppError {
            generationError = error
            phase = .review
        } catch {
            generationError = .transport(String(describing: type(of: error)))
            phase = .review
        }
    }

    func enrichAutomatically() async {
        if !hasPrepared { await prepare() }
        generationError = nil
        phase = .generatingTitle

        do {
            let suggestion = try await repository.suggestTitle(titleRequest)
            title = suggestion.title
            description = suggestion.description
        } catch let error as AppError {
            finishTitleFailure(error)
            return
        } catch {
            finishTitleFailure(.transport(String(describing: type(of: error))))
            return
        }

        phase = .generatingCover
        do {
            let suggestion = try await repository.suggestCover(coverRequest)
            generatedCoverPath = suggestion.coverURL
            uploadedCover = nil
            generationError = nil
        } catch let error as AppError {
            generationError = error
        } catch {
            generationError = .transport(String(describing: type(of: error)))
        }
        phase = .review
    }

    func publish() async {
        guard phase != .publishing else { return }
        guard let audio else { phase = .failed(.invalidRequest(loc(.errorNoAudio))); return }
        let cover: DraftCover
        if let uploadedCover { cover = .upload(uploadedCover) }
        else if let generatedCoverPath { cover = .generated(path: generatedCoverPath) }
        else { phase = .failed(.invalidRequest(loc(.errorCoverEmpty))); return }

        do {
            try DraftConstraints.validate(title: title, description: description, locationName: place?.name ?? "")
            phase = .publishing
            let created = try await repository.create(CreateSoundscapeDraft(
                audio: audio,
                cover: cover,
                title: title,
                description: description,
                latitude: place?.latitude,
                longitude: place?.longitude,
                locationName: place?.name ?? "",
                category: category,
                promptText: prompt,
                personalSocial: personalSocial,
                memoryPresent: memoryPresent,
                isPublic: isPublic
            ))
            phase = .published(created)
        } catch let error as AppError {
            phase = .failed(error)
        } catch {
            phase = .failed(.transport(String(describing: type(of: error))))
        }
    }

    func recover() {
        if audio == nil { phase = .idle } else { phase = .review }
    }

    func reset() async {
        await recorder.cancel()
        phase = .idle
        audio = nil
        uploadedCover = nil
        generatedCoverPath = nil
        place = nil
        locationStatus = .idle
        generationError = nil
        hasPrepared = false
        title = ""
        description = ""
        category = SoundscapeCategory.place.rawValue
        personalSocial = 0.5
        memoryPresent = 0.5
        isPublic = true
        await prepare()
    }

    private var titleRequest: TitleSuggestionRequest {
        TitleSuggestionRequest(
            locationName: place?.name ?? "",
            promptText: prompt,
            personalSocial: personalSocial,
            memoryPresent: memoryPresent
        )
    }

    private var coverRequest: CoverSuggestionRequest {
        CoverSuggestionRequest(title: title, locationName: place?.name ?? "", mood: category)
    }

    private func finishTitleFailure(_ error: AppError) {
        title = ""
        description = ""
        generationError = error
        phase = .review
    }
}
