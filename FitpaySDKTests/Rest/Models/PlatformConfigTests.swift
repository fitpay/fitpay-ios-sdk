import XCTest
import Nimble

@testable import FitpaySDK

class PlatformConfigTests: XCTestCase {
    let mockModels = MockModels()
    
    func testConfigParsing() {
        let config = mockModels.getPlatformConfig()
        
        expect(config?.isUserEventStreamsEnabled).to(beTrue())
    }
}
