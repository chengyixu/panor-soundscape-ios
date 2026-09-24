import Foundation

struct APIEnvironment: Sendable, Equatable {
    let siteBaseURL: URL
    let soundscapeAPIBaseURL: URL
    let authAPIBaseURL: URL

    static let production = APIEnvironment(
        siteBaseURL: URL(string: "https://www.panor.tech")!,
        soundscapeAPIBaseURL: URL(string: "https://www.panor.tech/soundscape/api")!,
        authAPIBaseURL: URL(string: "https://www.panor.tech/api/auth")!
    )

    func mediaURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }
        return URL(string: path, relativeTo: siteBaseURL)?.absoluteURL
    }
}

enum SoundscapeAPIPath: Sendable, Equatable {
    case health
    case soundscapes
    case soundscape(Int)
    case play(Int)
    case save(Int)
    case visibility(Int)
    case mySoundscapes
    case savedSoundscapes
    case rankings
    case aiTitle
    case aiCover
    case stagedCoverName(String)
    case feedback
    case report(Int)
    case blockCreator(String)
    case moderatorAccess
    case pendingModeration
    case moderatorAudio(Int)
    case moderatorCover(Int)
    case moderationReports
    case resolveReport(Int)
    case moderationDecision(Int, String)
    case suspendCreator(String)

    var value: String {
        switch self {
        case .health: "/health"
        case .soundscapes: "/soundscapes"
        case .soundscape(let id): "/soundscapes/\(id)"
        case .play(let id): "/soundscapes/\(id)/play"
        case .save(let id): "/soundscapes/\(id)/save"
        case .visibility(let id): "/soundscapes/\(id)/visibility"
        case .mySoundscapes: "/me/soundscapes"
        case .savedSoundscapes: "/me/saved"
        case .rankings: "/rankings"
        case .aiTitle: "/ai/title"
        case .aiCover: "/ai/cover"
        case .stagedCoverName(let name): "/staged-covers/\(name)"
        case .feedback: "/feedback"
        case .report(let id): "/soundscapes/\(id)/report"
        case .blockCreator(let id): "/users/\(id)/block"
        case .moderatorAccess: "/moderation/access"
        case .pendingModeration: "/moderation/pending"
        case .moderatorAudio(let id): "/moderation/soundscapes/\(id)/media/audio"
        case .moderatorCover(let id): "/moderation/soundscapes/\(id)/media/cover"
        case .moderationReports: "/moderation/reports"
        case .resolveReport(let id): "/moderation/reports/\(id)/resolve"
        case .moderationDecision(let id, let action): "/moderation/soundscapes/\(id)/\(action)"
        case .suspendCreator(let id): "/moderation/users/\(id)/suspend"
        }
    }
}

enum AuthAPIPath: String, Sendable {
    case register = "/register"
    case login = "/login"
    case me = "/me"
    case google = "/google"
    case logout = "/logout"
    case config = "/config"
    case apple = "/apple"
}
