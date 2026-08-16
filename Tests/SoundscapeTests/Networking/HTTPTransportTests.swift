import XCTest
@testable import Soundscape

final class HTTPTransportTests: XCTestCase {
    func testProductionTransportDoesNotInheritLoopbackSystemProxy() {
        let configuration = URLSessionTransport.directConfiguration()

        XCTAssertEqual(configuration.connectionProxyDictionary?.count, 0)
        XCTAssertFalse(configuration.waitsForConnectivity)
    }
}
