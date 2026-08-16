import AVFoundation
import Foundation
import OSLog

protocol RecordingService: Sendable {
    func start() async throws
    func stop() async throws -> MediaFile
    func cancel() async
}

actor AVRecordingService: RecordingService {
    private var recorder: AVAudioRecorder?
    private var outputURL: URL?
    private let logger = Logger(subsystem: "tech.panor.soundscape", category: "recording")

    func start() async throws {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else { throw AppError.microphonePermissionDenied }
        try await AudioSessionLifecycle.activate(.recording)
        do {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("soundscape-\(UUID().uuidString)")
                .appendingPathExtension("m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            guard recorder.record() else { throw AppError.recordingUnavailable }
            self.recorder = recorder
            outputURL = url
        } catch {
            await deactivateSession()
            throw error
        }
    }

    func stop() async throws -> MediaFile {
        guard let recorder, let outputURL else { throw AppError.recordingUnavailable }
        recorder.stop()
        self.recorder = nil
        self.outputURL = nil
        do {
            let data = try Data(contentsOf: outputURL)
            cleanupFile(at: outputURL)
            await deactivateSession()
            return try MediaConstraints.audio(data: data, filename: "recording.m4a", contentType: "audio/mp4")
        } catch {
            cleanupFile(at: outputURL)
            await deactivateSession()
            throw error
        }
    }

    func cancel() async {
        recorder?.stop()
        recorder = nil
        if let outputURL { cleanupFile(at: outputURL) }
        outputURL = nil
        await deactivateSession()
    }

    private func cleanupFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            logger.error("Temporary recording cleanup failed")
        }
    }

    private func deactivateSession() async {
        do {
            try await AudioSessionLifecycle.deactivate()
        } catch {
            logger.error("Recording audio session deactivation failed")
        }
    }
}
