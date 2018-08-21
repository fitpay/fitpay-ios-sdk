import XCTest
@testable import FitpaySDK

class PayloadTests: XCTestCase {
    let mockModels = MockModels()

    func testCreditCardPayloadParsing() {
        let payload = mockModels.getPayload()

        XCTAssertNotNil(payload?.creditCard)
        XCTAssertNotNil(payload?.apduPackage)

        let json = payload?.toJSON()
        XCTAssertNotNil(json?["creditCardId"])
        XCTAssertNotNil(json?["packageId"])
    }
}
