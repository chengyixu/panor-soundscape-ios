import AVFoundation
import Foundation

enum AudioSessionProfile: Sendable {
    case playback
    case recording
}

enum AudioSessionLifecycle {
    struct Configuration: Equatable {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    private enum LifecycleError: Error {
        case activationRejected
        case deactivationRejected
    }

    static func activate(_ profile: AudioSessionProfile) async throws {
        try await performBlocking {
            let session = AVAudioSession.sharedInstance()
            let configuration = configuration(for: profile)
            try session.setCategory(
                configuration.category,
                mode: configuration.mode,
                options: configuration.options
            )
        }

        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                AVAudioSession.sharedInstance().activate(options: []) { activated, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if activated {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: LifecycleError.activationRejected)
                    }
                }
            }
        } else {
            try await activateLegacySession()
        }
        #else
        try await activateLegacySession()
        #endif
    }

    static func deactivate() async throws {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                AVAudioSession.sharedInstance().deactivate(options: [.notifyOthersOnDeactivation]) { deactivated, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if deactivated {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: LifecycleError.deactivationRejected)
                    }
                }
            }
        } else {
            try await deactivateLegacySession()
        }
        #else
        try await deactivateLegacySession()
        #endif
    }

    private static func activateLegacySession() async throws {
        try await performBlocking {
            try AVAudioSession.sharedInstance().setActive(true)
        }
    }

    private static func deactivateLegacySession() async throws {
        try await performBlocking {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    static func configuration(for profile: AudioSessionProfile) -> Configuration {
        switch profile {
        case .playback:
            Configuration(category: .playback, mode: .spokenAudio, options: [])
        case .recording:
            Configuration(
                category: .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
        }
    }

    private static func performBlocking(_ operation: @escaping @Sendable () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try operation()
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
