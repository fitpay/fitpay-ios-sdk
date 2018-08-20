import XCTest
@testable import FitpaySDK

class IssuersTests: BaseTestProvider {
        
    func testIssuersParsing() {
        let issuers = mockModels.getIssuers()

        XCTAssertNotNil(issuers?.links)
        XCTAssertNotNil(issuers?.countries)

        let json = issuers?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertNotNil(json?["countries"])
    }
}
