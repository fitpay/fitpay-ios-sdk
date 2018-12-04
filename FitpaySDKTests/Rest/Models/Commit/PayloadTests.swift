import XCTest
import Nimble

@testable import FitpaySDK

class PayloadTests: XCTestCase {
    let mockModels = MockModels()

    func testCreditCardPayloadParsing() {
        let payload = mockModels.getPayload()

        expect(payload?.creditCard).toNot(beNil())
        expect(payload?.apduPackage).toNot(beNil())

        let json = payload?.toJSON()
        expect(json?["creditCardId"]).toNot(beNil())
        expect(json?["packageId"]).toNot(beNil())
    }
}
