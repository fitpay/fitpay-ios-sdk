import XCTest
import Nimble

@testable import FitpaySDK

class UIntExtensionsTests: XCTestCase {
    
    func testUInt8data() {
        let testInt8: UInt8 = 0x22
        expect(testInt8).to(equal(34))
        
        let testData = testInt8.data
        expect(testData).to(equal(Data(bytes: [testInt8])))
    }
    
    func testUInt16data() {
        let testInt8: UInt8 = 0x22
        let testInt8Second: UInt8 = 0x34

        let testInt16: UInt16 = 0x2234 // big endian
        
        expect(testInt16).to(equal(8756))
        
        let testData = testInt16.data //returns little endian
        expect(testData).to(equal(Data(bytes: [testInt8Second, testInt8])))
    }

}
