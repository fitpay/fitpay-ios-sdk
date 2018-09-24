import XCTest
import Nimble

@testable import FitpaySDK

class A2AContextTests: XCTestCase {
    
    func testCreatingModelFromDictionary() {
        let testJSON: [String: Any] = ["applicationId": "123456789", "action": "action://", "payload": "thisisapayload"]
        
        guard let a2aContext = try? A2AContext(testJSON) else {
            fail("nil a2aContext")
            return
        }
        
        expect(a2aContext.applicationId).to(equal("123456789"))
        expect(a2aContext.action).to(equal("action://"))
        expect(a2aContext.payload).to(equal("thisisapayload"))

    }
    
}
