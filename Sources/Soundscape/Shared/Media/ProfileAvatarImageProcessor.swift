import ImageIO
import UIKit

enum ProfileAvatarImageProcessor {
    static func normalizedJPEG(from data: Data) throws -> Data {
        guard !data.isEmpty, data.count <= MediaConstraints.maximumCoverBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 512
              ] as CFDictionary) else {
            throw AppError.invalidRequest(loc(.errorInvalidImage))
        }
        let image = UIImage(cgImage: thumbnail)
        let size = CGSize(width: 256, height: 256)
        let side = min(image.size.width, image.size.height)
        let crop = CGRect(x: (image.size.width - side) / 2, y: (image.size.height - side) / 2, width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let square = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(x: -crop.minX * size.width / side,
                                   y: -crop.minY * size.height / side,
                                   width: image.size.width * size.width / side,
                                   height: image.size.height * size.height / side))
        }
        guard let jpeg = square.jpegData(compressionQuality: 0.78), jpeg.count <= 256_000 else {
            throw AppError.invalidRequest(loc(.errorCannotProcessImage))
        }
        return jpeg
    }
}
