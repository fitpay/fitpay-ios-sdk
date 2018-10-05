import XCTest
import Nimble

@testable import FitpaySDK

class NSErrorExtensionsTests: XCTestCase {
    
    func testErrorIntCode() {
        let testObject = true
        let error = NSError.error(code: 123, domain: testObject, message: "Message")

        expect(error.code).to(equal(123))
        expect(error.domain).to(equal("true"))
        expect(error.localizedDescription).to(equal("Message"))
    }
    
}
