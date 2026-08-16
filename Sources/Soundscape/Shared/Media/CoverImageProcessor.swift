import UIKit

enum CoverImageProcessor {
    static let maximumPixelDimension: CGFloat = 1_600
    static let jpegQuality: CGFloat = 0.84

    static func normalizedJPEG(from data: Data) throws -> Data {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
            throw AppError.invalidRequest(loc(.errorInvalidImage))
        }

        let scale = min(1, maximumPixelDimension / max(image.size.width, image.size.height))
        let outputSize = CGSize(
            width: max(1, (image.size.width * scale).rounded()),
            height: max(1, (image.size.height * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        let normalized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: outputSize)) }
        guard let jpeg = normalized.jpegData(compressionQuality: jpegQuality) else {
            throw AppError.invalidRequest(loc(.errorCannotProcessImage))
        }
        try MediaConstraints.validateCoverByteCount(jpeg.count)
        return jpeg
    }
}
