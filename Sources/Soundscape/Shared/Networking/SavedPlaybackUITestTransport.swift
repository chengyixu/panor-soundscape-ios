#if DEBUG
import Foundation

/// Hermetic XCUITest boundary. No network requests or real saved-list mutations.
/// Not present in Release builds and activated only by an explicit test flag.
actor SavedPlaybackUITestTransport: HTTPTransport {
    private let emptySaved: Bool
    private let savedIDs = Set([9002, 9003])

    init(emptySaved: Bool) { self.emptySaved = emptySaved }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let audio = Bundle.main.url(forResource: "AutoplayTestTone", withExtension: "m4a") else {
            throw AppError.invalidRequest(loc(.errorNoAudio))
        }
        let theme: [String: Any] = ["id": 9, "title": "City cycling", "description": "Along the route", "kind": "topic", "recording_count": 3]
        let rows: [[String: Any]] = [
            (9001, "All forest"), (9002, "Saved rain"), (9003, "Saved shore")
        ].map { id, title in
            ["id": id, "user_id": "ui-creator", "author_name": "Soundscape", "title": title,
             "audio_url": audio.absoluteString, "category": SoundscapeCategory.nature.rawValue, "duration_sec": 3,
             "is_public": 1, "moderation_status": "approved", "theme": theme,
             "lat": 22.3, "lng": 114.2, "location_name": "Harbour"]
        }
        let payload: Any
        var status = 200
        let environment = APIEnvironment.production
        let path = url.path.hasPrefix(environment.soundscapeAPIBaseURL.path)
            ? String(url.path.dropFirst(environment.soundscapeAPIBaseURL.path.count)) : url.path
        switch path {
        case environment.authAPIBaseURL.path + AuthAPIPath.me.rawValue:
            payload = ["success": true, "user": ["id": "ui-listener", "name": "Listener", "email": "listener@example.invalid"]]
        case SoundscapeAPIPath.soundscapes.value, SoundscapeAPIPath.themeRecordings(9).value: payload = rows
        case SoundscapeAPIPath.themes.value: payload = [theme]
        case SoundscapeAPIPath.savedSoundscapes.value: payload = emptySaved ? [] : rows.filter { savedIDs.contains($0["id"] as! Int) }
        case SoundscapeAPIPath.mySoundscapes.value, SoundscapeAPIPath.rankings.value: payload = []
        case SoundscapeAPIPath.moderatorAccess.value: status = 403; payload = ["detail": "moderator access required"]
        default:
            if url.path.hasSuffix("/play") { payload = ["ok": true, "full_play": false] }
            else { status = 404; payload = ["detail": "test endpoint unavailable"] }
        }
        return (try JSONSerialization.data(withJSONObject: payload), HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!)
    }
}

actor SavedPlaybackUITestTokenStore: AuthTokenStore {
    private var value: String?
    init(signedIn: Bool) { value = signedIn ? "ui-saved-session" : nil }
    func token() -> String? { value }
    func setToken(_ token: String) { value = token }
    func clear() { value = nil }
}
#endif
