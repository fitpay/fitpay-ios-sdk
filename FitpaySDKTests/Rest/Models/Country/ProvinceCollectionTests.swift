import XCTest
import Nimble

@testable import FitpaySDK

class ProvinceCollectionTests: XCTestCase {
    
    private let mockModels = MockModels()
    
    func testProvinceCollectionParsing() {
        let provinceCollection = mockModels.getProvinceCollection()
        
        expect(provinceCollection?.iso).to(equal("US"))
        expect(provinceCollection?.name).to(equal("United States"))
        expect(provinceCollection?.provinces["CO"]).toNot(beNil())
        expect(provinceCollection?.provinceList.count).to(equal(1))
        
        let json = provinceCollection?.toJSON()
        expect(json?["iso"] as? String).to(equal("US"))
        expect(json?["name"] as? String).to(equal("United States"))
        expect(json?["provinces"]).toNot(beNil())

    }
    
}
