import XCTest
@testable import FitpaySDK

class A2AContextTests: XCTestCase {
    
    func testCreatingModelFromDictionary() {
        let testJSON: [String: Any] = ["applicationId": "123456789", "action": "action://", "payload": "thisisapayload"]
        
        guard let a2aContext = try? A2AContext(testJSON) else {
            XCTFail()
            return
        }
        
        XCTAssert(a2aContext.applicationId == "123456789")
        XCTAssert(a2aContext.action == "action://")
        XCTAssert(a2aContext.payload == "thisisapayload")

    }
    
}

