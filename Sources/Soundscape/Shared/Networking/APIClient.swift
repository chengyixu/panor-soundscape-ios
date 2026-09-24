import Foundation
import OSLog

struct APIErrorEnvelope: Decodable, Sendable {
    struct StructuredDetail: Decodable, Sendable {
        let code: String?
        let message: String?
    }

    let detail: Detail?
    let message: String?

    enum Detail: Decodable, Sendable {
        case text(String)
        case structured(StructuredDetail)
        case validation

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let text = try? container.decode(String.self) {
                self = .text(text)
            } else if let structured = try? container.decode(StructuredDetail.self) {
                self = .structured(structured)
            } else {
                self = .validation
            }
        }
    }
}

actor APIClient {
    private static let transportRetryDelay: Duration = .milliseconds(400)

    private let transport: any HTTPTransport
    private let tokenStore: any AuthTokenStore
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let logger = Logger(subsystem: "tech.panor.soundscape", category: "network")

    init(transport: any HTTPTransport, tokenStore: any AuthTokenStore) {
        self.transport = transport
        self.tokenStore = tokenStore
    }

    func request<Response: Decodable & Sendable>(
        baseURL: URL,
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil,
        authenticated: Bool = false,
        optionalAuthentication: Bool = false,
        timeoutInterval: TimeInterval = 30
    ) async throws -> Response {
        let request = try await makeRequest(
            baseURL: baseURL,
            path: path,
            method: method,
            query: query,
            body: body,
            authenticated: authenticated,
            optionalAuthentication: optionalAuthentication,
            timeoutInterval: timeoutInterval
        )
        return try await execute(request)
    }

    func upload<Response: Decodable & Sendable>(
        baseURL: URL,
        path: String,
        multipart: MultipartBody,
        authenticated: Bool
    ) async throws -> Response {
        let url = endpointURL(baseURL: baseURL, path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.data
        if authenticated {
            guard let token = try await tokenStore.token(), !token.isEmpty else {
                throw AppError.authenticationRequired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await execute(request)
    }

    func download(baseURL: URL, path: String, maximumBytes: Int = 50_000_000) async throws -> Data {
        let request = try await makeRequest(baseURL: baseURL, path: path, method: "GET", query: [], body: nil, authenticated: true, optionalAuthentication: false, timeoutInterval: 60)
        do {
            let (data, response) = try await transport.data(for: request)
            guard (200..<300).contains(response.statusCode) else { throw decodeError(data: data, status: response.statusCode) }
            guard !data.isEmpty, data.count <= maximumBytes else { throw AppError.invalidRequest(loc(.errorAudioTooLarge)) }
            return data
        } catch let error as AppError { throw error }
        catch { throw AppError.transport(String(describing: type(of: error))) }
    }

    private func makeRequest(
        baseURL: URL,
        path: String,
        method: String,
        query: [URLQueryItem],
        body: (any Encodable & Sendable)?,
        authenticated: Bool,
        optionalAuthentication: Bool,
        timeoutInterval: TimeInterval
    ) async throws -> URLRequest {
        let base = endpointURL(baseURL: baseURL, path: path)
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw AppError.invalidRequest(loc(.errorInvalidURL))
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw AppError.invalidRequest(loc(.errorInvalidParams)) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authenticated {
            guard let token = try await tokenStore.token(), !token.isEmpty else {
                throw AppError.authenticationRequired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if optionalAuthentication, let token = try await tokenStore.token(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func endpointURL(baseURL: URL, path: String) -> URL {
        path.split(separator: "/").reduce(baseURL) { partial, component in
            partial.appendingPathComponent(String(component))
        }
    }

    private func execute<Response: Decodable & Sendable>(_ request: URLRequest) async throws -> Response {
        do {
            return try await performOnce(request)
        } catch let error as AppError {
            guard request.httpMethod == "GET", case .transport = error else { throw error }
            guard !Task.isCancelled else { throw error }
            logger.info("Retrying idempotent request path=\(request.url?.path ?? "unknown", privacy: .public) after=\(String(describing: error), privacy: .public)")
            try? await Task.sleep(for: Self.transportRetryDelay)
            do {
                return try await performOnce(request)
            } catch let retryError as AppError {
                throw retryError
            } catch {
                throw AppError.transport(String(describing: type(of: error)))
            }
        } catch let error as URLError {
            logger.error("Transport failed path=\(request.url?.path ?? "unknown", privacy: .public) code=\(error.code.rawValue)")
            throw AppError.transport("URLError.\(error.code.rawValue)")
        } catch {
            logger.error("Transport failed path=\(request.url?.path ?? "unknown", privacy: .public) type=\(String(describing: type(of: error)), privacy: .public)")
            throw AppError.transport(String(describing: type(of: error)))
        }
    }

    private func performOnce<Response: Decodable & Sendable>(_ request: URLRequest) async throws -> Response {
        do {
            let (data, response) = try await transport.data(for: request)
            guard (200..<300).contains(response.statusCode) else {
                logger.error("HTTP request failed path=\(request.url?.path ?? "unknown", privacy: .public) status=\(response.statusCode)")
                throw decodeError(data: data, status: response.statusCode)
            }
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw AppError.decoding
            }
        } catch let error as AppError {
            throw error
        } catch let error as URLError {
            logger.error("Transport failed path=\(request.url?.path ?? "unknown", privacy: .public) code=\(error.code.rawValue)")
            throw AppError.transport("URLError.\(error.code.rawValue)")
        } catch {
            logger.error("Transport failed path=\(request.url?.path ?? "unknown", privacy: .public) type=\(String(describing: type(of: error)), privacy: .public)")
            throw AppError.transport(String(describing: type(of: error)))
        }
    }

    private func decodeError(data: Data, status: Int) -> AppError {
        let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
        switch envelope?.detail {
        case .text(let message):
            return .server(status: status, code: nil, message: message)
        case .structured(let detail):
            return .server(
                status: status,
                code: detail.code,
                message: detail.message ?? loc(.errorServerFailed)
            )
        default:
            return .server(
                status: status,
                code: nil,
                message: envelope?.message ?? loc(.errorServerFailed)
            )
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
