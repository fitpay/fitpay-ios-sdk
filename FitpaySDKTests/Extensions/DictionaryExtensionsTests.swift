import XCTest
import Nimble

@testable import FitpaySDK

class DictionaryExtensionsTests: XCTestCase {
    
    func testJSONString() {
        let testDict: [String: Any] = ["foo": "bar", "number": 1]
        expect(testDict.JSONString).to(contain("\"foo\":\"bar\""))
        expect(testDict.JSONString).to(contain("\"number\":1"))
    }
    
    func testPlusEquals() {
        var testDict1: [String: String] = ["foo": "bar", "foo2": "bar2"]
        let testDict2: [String: String] = ["foo3": "bar3", "foo2": "newBar"]

        testDict1 += testDict2
        
        expect(testDict1.keys.count).to(equal(3))
        expect(testDict2.keys.count).to(equal(2))
        
        expect(testDict1["foo"]).to(equal("bar"))
        expect(testDict1["foo2"]).to(equal("newBar"))
        expect(testDict1["foo3"]).to(equal("bar3"))
        
    }
    
    func testPlus() {
        let testDict1: [String: String] = ["foo": "bar", "foo2": "bar2"]
        let testDict2: [String: String] = ["foo3": "bar3", "foo2": "newBar"]
        
        let testDict3 = testDict1 + testDict2
        
        expect(testDict1.keys.count).to(equal(2))
        expect(testDict2.keys.count).to(equal(2))
        expect(testDict3.keys.count).to(equal(3))

        expect(testDict3["foo"]).to(equal("bar"))
        expect(testDict3["foo2"]).to(equal("newBar"))
        expect(testDict3["foo3"]).to(equal("bar3"))
    }
    
}
