import XCTest
import Nimble

@testable import FitpaySDK

class ProvinceTests: XCTestCase {
    private let mockModels = MockModels()

    func testProvinceParsing() {
        let province = mockModels.getProvince()
        
        expect(province?.iso).to(equal("CO"))
        expect(province?.name).to(equal("Colorado"))
                
        let json = province?.toJSON()
        expect(json?["iso"] as? String).to(equal("CO"))
        expect(json?["name"] as? String).to(equal("Colorado"))
    }
}
