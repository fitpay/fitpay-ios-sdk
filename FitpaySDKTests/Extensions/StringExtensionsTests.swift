import XCTest
import Nimble

@testable import FitpaySDK

class StringExtensionsTests: XCTestCase {
    
    func testHexToData() {
        let fooData = "0012".hexToData()
        expect(fooData).toNot(beNil())
        // create more tests here
    }
    
    func testHexToDataInvlaid() {
        let fooData = "123".hexToData()
        expect(fooData).to(beNil())
    }
    
}
