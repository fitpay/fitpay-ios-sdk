import XCTest
import Nimble

@testable import FitpaySDK

class APDUResponseTypeTest: XCTestCase {

    func testSuccesCode() {
        let responseType = APDUResponseType(withCode: [0x90, 0x00])
        expect(responseType).to(equal(APDUResponseType.success))
    }

    func testWarningCode() {
        let responseType = APDUResponseType(withCode:  [0x62, 0x63])
        expect(responseType).to(equal(APDUResponseType.warning))

    }

    func testConcatenationCode() {
        let responseType = APDUResponseType(withCode: [0x61, 0x63])
        expect(responseType).to(equal(APDUResponseType.concatenation))

    }

    func testErrorCode() {
        let responseType = APDUResponseType(withCode: [0x61])
        expect(responseType).to(equal(APDUResponseType.error))
    }
}
