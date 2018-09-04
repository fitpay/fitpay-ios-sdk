import XCTest
import Nimble

@testable import FitpaySDK

class JSONCodingKeysTests: XCTestCase {

    func testStringInit() {
        let jsonKey = JSONCodingKeys(stringValue: "test")
        expect(jsonKey?.stringValue).to(equal("test"))
        expect(jsonKey?.intValue).to(beNil())
    }
    
    func testIntInit() {
        let jsonKey = JSONCodingKeys(intValue: 10)
        expect(jsonKey?.stringValue).to(equal("10"))
        expect(jsonKey?.intValue).to(equal(10))
    }
    
}
