import Foundation

struct MultipartBody: Sendable {
    let data: Data
    let boundary: String
    var contentType: String { "multipart/form-data; boundary=\(boundary)" }
}

struct MultipartBuilder {
    private let boundary = "SoundscapeBoundary-\(UUID().uuidString)"
    private var data = Data()

    mutating func addField(name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func addFile(name: String, file: MediaFile) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\r\n")
        append("Content-Type: \(file.contentType)\r\n\r\n")
        data.append(file.data)
        append("\r\n")
    }

    mutating func build() -> MultipartBody {
        append("--\(boundary)--\r\n")
        return MultipartBody(data: data, boundary: boundary)
    }

    private mutating func append(_ string: String) {
        data.append(Data(string.utf8))
    }
}
