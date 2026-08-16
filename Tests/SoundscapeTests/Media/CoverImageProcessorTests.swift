import UIKit
import XCTest
@testable import Soundscape

final class CoverImageProcessorTests: XCTestCase {
    func testNormalizesLargeImageToBoundedOpaqueJPEG() throws {
        let source = UIGraphicsImageRenderer(size: CGSize(width: 3_200, height: 1_600)).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3_200, height: 1_600))
        }
        let png = try XCTUnwrap(source.pngData())

        let normalized = try CoverImageProcessor.normalizedJPEG(from: png)
        let image = try XCTUnwrap(UIImage(data: normalized))

        XCTAssertEqual(image.size.width, 1_600, accuracy: 1)
        XCTAssertEqual(image.size.height, 800, accuracy: 1)
        XCTAssertLessThanOrEqual(normalized.count, MediaConstraints.maximumCoverBytes)
        XCTAssertEqual(Array(normalized.prefix(2)), [0xFF, 0xD8])
    }

    func testRejectsUnreadableImageData() {
        XCTAssertThrowsError(try CoverImageProcessor.normalizedJPEG(from: Data([0x00, 0x01]))) { error in
            XCTAssertEqual(error as? AppError, .invalidRequest(loc(.errorInvalidImage)))
        }
    }
}
