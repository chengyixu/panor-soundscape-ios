import Foundation

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

actor URLSessionTransport: HTTPTransport {
    private let session: URLSession

    init(session: URLSession? = nil) {
        self.session = session ?? URLSession(configuration: Self.directConfiguration())
    }

    static func directConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = [:]
        configuration.waitsForConnectivity = false
        return configuration
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw AppError.transport("non-http response")
        }
        return (data, response)
    }
}
