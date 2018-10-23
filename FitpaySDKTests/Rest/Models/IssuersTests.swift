import XCTest
import Nimble

@testable import FitpaySDK

class IssuersTests: XCTestCase {
    let mockModels = MockModels()
        
    func testIssuersParsing() {
        let issuers = mockModels.getIssuers()

        expect(issuers?.countries).toNot(beNil())
        expect(issuers?.countries?["US"]).toNot(beNil())
        expect(issuers?.countries?["US"]?.cardNetworks).toNot(beNil())
        expect(issuers?.countries?["US"]?.cardNetworks?["VISA"]).toNot(beNil())
        expect(issuers?.countries?["US"]?.cardNetworks?["VISA"]?.issuers).to(contain("Capital One"))
        
        let json = issuers?.toJSON()
        expect(json?["countries"]).toNot(beNil())
    }
}
