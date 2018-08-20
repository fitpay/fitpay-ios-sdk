import XCTest
@testable import FitpaySDK

class APDUResponseTypeTest: XCTestCase {

    func testSuccesCode() {
        let responceType = APDUResponseType(withCode: [0x90, 0x00])
        XCTAssertEqual(responceType, APDUResponseType.success)
    }

    func testWarningCode() {
        let responceType = APDUResponseType(withCode:  [0x62, 0x63])
        XCTAssertEqual(responceType, APDUResponseType.warning)
    }

    func testConcatenationCode() {
        let responceType = APDUResponseType(withCode: [0x61, 0x63])
        XCTAssertEqual(responceType, APDUResponseType.concatenation)
    }

    func testErrorCode() {
        let responceType = APDUResponseType(withCode: [0x61])
        XCTAssertEqual(responceType, APDUResponseType.error)
    }
}
