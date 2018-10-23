import XCTest
import Nimble

@testable import FitpaySDK

class ResourceLinkTests: XCTestCase {
    
    func testResetDeviceResultParsing() {
        let resourceLink1 = ResourceLink(target: "Foo", href: "FooHref")
        let resourceLink2 = ResourceLink(target: "Foo", href: "FooHref")
        
        expect(resourceLink1).to(equal(resourceLink2))
    }
}
