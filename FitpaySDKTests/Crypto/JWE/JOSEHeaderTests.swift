import XCTest
import Nimble

@testable import FitpaySDK

class JOSEHeaderTests: XCTestCase {
    
    func testInit() {
        let joseHeader = JOSEHeader(encryption: JWTEncryption.A256GCM, algorithm: JWTAlgorithm.A256GCMKW)
        expect(joseHeader.enc).to(equal(.A256GCM))
        expect(joseHeader.alg).to(equal(.A256GCMKW))

    }
    
}
