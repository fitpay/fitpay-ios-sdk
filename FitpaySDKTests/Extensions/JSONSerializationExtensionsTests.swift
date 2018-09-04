import XCTest
import Nimble

@testable import FitpaySDK

class JSONSerializationExtensionsTests: XCTestCase {

    func testJSONString() {
        let testDict: [String: Any] = ["foo": "bar", "number": 1]
        let jsonString = JSONSerialization.JSONString(testDict)
        expect(jsonString).toNot(beNil())
        expect(testDict.JSONString).to(contain("\"foo\":\"bar\""))
        expect(testDict.JSONString).to(contain("\"number\":1"))
    }
    
}
