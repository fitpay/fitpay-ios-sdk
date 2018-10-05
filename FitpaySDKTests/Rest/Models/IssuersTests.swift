import XCTest
import Nimble

@testable import FitpaySDK

class IssuersTests: XCTestCase {
    let mockModels = MockModels()
        
    func testIssuersParsing() {
        let issuers = mockModels.getIssuers()

        expect(issuers?.links).toNot(beNil())
        expect(issuers?.countries).toNot(beNil())

        let json = issuers?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["countries"]).toNot(beNil())
    }
}
