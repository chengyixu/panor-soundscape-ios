import Foundation

actor ProtectedFileResonanceStateStore: ResonanceStatePersisting {
    private let fileURL: URL

    init(fileURL: URL = ProtectedFileResonanceStateStore.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func load() async throws -> ResonancePersonalizationState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(ResonancePersonalizationState.self, from: data)
        } catch {
            throw AppError.personalizationUnavailable
        }
    }

    func save(_ state: ResonancePersonalizationState) async throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            throw AppError.personalizationUnavailable
        }
    }

    func reset() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw AppError.personalizationUnavailable
        }
    }

    private static func defaultFileURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Soundscape", isDirectory: true)
            .appendingPathComponent("personalization-v1.json", isDirectory: false)
    }
}
