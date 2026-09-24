import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    let soundscapes: any SoundscapeRepository
    let identity: any IdentityRepository
    let moderation: any ModerationRepository
    let recorder: any RecordingService
    let location: any LocationProviding
    let matching: any ResonanceMatching
    let intentParser: any ResonanceIntentParsing
    let player: AudioPlayerController
    let session: IdentitySession

    init(
        soundscapes: any SoundscapeRepository,
        identity: any IdentityRepository,
        moderation: any ModerationRepository,
        recorder: any RecordingService,
        location: any LocationProviding,
        matching: any ResonanceMatching,
        intentParser: any ResonanceIntentParsing,
        player: AudioPlayerController,
        session: IdentitySession
    ) {
        self.soundscapes = soundscapes
        self.identity = identity
        self.moderation = moderation
        self.recorder = recorder
        self.location = location
        self.matching = matching
        self.intentParser = intentParser
        self.player = player
        self.session = session
    }

    static func live() -> AppContainer {
        let environment = APIEnvironment.production
        let keychainService = ProcessInfo.processInfo.environment["SOUNDSCAPE_KEYCHAIN_SERVICE"]
            ?? KeychainTokenStore.defaultService
        let tokenStore = KeychainTokenStore(service: keychainService)
        let transport = URLSessionTransport()
        let client = APIClient(transport: transport, tokenStore: tokenStore)
        let remoteSoundscapes = RemoteSoundscapeRepository(environment: environment, client: client)
        // The pre-moderation release stored public UGC on disk. Never read it
        // after adding server-side takedowns and viewer-specific blocks.
        let oldSnapshot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Soundscape/public-content-v1.json")
        try? FileManager.default.removeItem(at: oldSnapshot)
        let soundscapes = CachedSoundscapeRepository(upstream: remoteSoundscapes)
        let identity = PanorIdentityRepository(environment: environment, client: client, tokenStore: tokenStore)
        let session = IdentitySession(repository: identity, avatarStore: DiskProfileAvatarStore())
        let matching = LocalResonanceMatchingService(
            repository: soundscapes,
            store: ProtectedFileResonanceStateStore()
        )
        let intentParser = LocalResonanceIntentParser()
        let player = AudioPlayerController(repository: soundscapes, matching: matching)
        return AppContainer(
            soundscapes: soundscapes,
            identity: identity,
            moderation: RemoteModerationRepository(environment: environment, client: client),
            recorder: AVRecordingService(),
            location: OneShotLocationProvider(),
            matching: matching,
            intentParser: intentParser,
            player: player,
            session: session
        )
    }
}
