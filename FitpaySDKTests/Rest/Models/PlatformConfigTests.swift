import XCTest
@testable import FitpaySDK

class PlatformConfigTests: BaseTestProvider {
    
    func testConfigParsing() {
        let config = mockModels.getPlatformConfig()
        
        XCTAssertEqual(config?.isUserEventStreamsEnabled, true)
    }
}
