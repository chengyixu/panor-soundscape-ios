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
    case rankings
    case aiTitle
    case aiCover
    case feedback

    var value: String {
        switch self {
        case .health: "/health"
        case .soundscapes: "/soundscapes"
        case .soundscape(let id): "/soundscapes/\(id)"
        case .play(let id): "/soundscapes/\(id)/play"
        case .save(let id): "/soundscapes/\(id)/save"
        case .visibility(let id): "/soundscapes/\(id)/visibility"
        case .mySoundscapes: "/me/soundscapes"
        case .rankings: "/rankings"
        case .aiTitle: "/ai/title"
        case .aiCover: "/ai/cover"
        case .feedback: "/feedback"
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
