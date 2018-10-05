import XCTest
import Nimble

@testable import FitpaySDK

class ResourceLinkTests: XCTestCase {
    
    func testResetDeviceResultParsing() {
        let resourceLink1 = ResourceLink()
        resourceLink1.target = "Foo"
        resourceLink1.href = "FooHref"
        
        let resourceLink2 = ResourceLink()
        resourceLink2.target = "Foo"
        resourceLink2.href = "FooHref"
        
        expect(resourceLink1).to(equal(resourceLink2))
    }
}
