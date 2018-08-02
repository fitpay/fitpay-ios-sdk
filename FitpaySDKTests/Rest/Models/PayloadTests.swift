import XCTest
@testable import FitpaySDK

import UIKit

class PayloadTests: BaseTestProvider {

    func testCreditCardPayloadParsing() {
        let payload = mockModels.getPayload()

        XCTAssertNotNil(payload?.creditCard)
        XCTAssertNotNil(payload?.apduPackage)

        let json = payload?.toJSON()
        XCTAssertNotNil(json?["creditCardId"])
        XCTAssertNotNil(json?["packageId"])
    }
}
