import XCTest
import Nimble

@testable import FitpaySDK

class JOSEHeaderTests: XCTestCase {
    
    func testInit() {
        let joseHeader = JOSEHeader(encryption: .A256GCM, algorithm: .A256GCMKW)
        
        expect(joseHeader.enc).to(equal(.A256GCM))
        expect(joseHeader.alg).to(equal(.A256GCMKW))
    }
    
}
