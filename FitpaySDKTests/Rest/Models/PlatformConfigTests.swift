import XCTest
@testable import FitpaySDK

class PlatformConfigTests: XCTestCase {
    let mockModels = MockModels()
    
    func testConfigParsing() {
        let config = mockModels.getPlatformConfig()
        
        XCTAssertEqual(config?.isUserEventStreamsEnabled, true)
    }
}
