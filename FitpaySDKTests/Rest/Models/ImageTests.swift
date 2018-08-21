import XCTest
@testable import FitpaySDK

class ImageTests: XCTestCase {
    let mockModels = MockModels()
        
    func testImageParsing() {
        let image = mockModels.getImage()

        XCTAssertNotNil(image?.links)
        XCTAssertEqual(image?.mimeType, "image/gif")
        XCTAssertEqual(image?.height, 20)
        XCTAssertEqual(image?.width, 60)

        let json = image?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["mimeType"] as? String, "image/gif")
        XCTAssertEqual(json?["height"] as? Int64, 20)
        XCTAssertEqual(json?["width"] as? Int64, 60)
    }
}
