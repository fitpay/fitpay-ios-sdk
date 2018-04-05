import XCTest
@testable import FitpaySDK

class JWETests: XCTestCase {
    let plainText = "{\"Hello world!\"}"
    let sharedSecret = "NFxCwmIncymviQp9-KKKgH_8McGHWGgwV-T-RNkMI-U".base64URLdecoded()
    
    func testJWEEncryption() {
        let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: plainText, keyId: nil)
        XCTAssertNotNil(jweObject as Any)
        
        let encryptResult = try? jweObject!.encrypt(sharedSecret!)
        XCTAssertNotNil(encryptResult as Any)
        
        let jweResult = JWEObject.parse(payload: encryptResult!!)
        let decryptResult = try? jweResult?.decrypt(sharedSecret!)
        XCTAssertNotNil(decryptResult as Any)
        
        XCTAssertTrue(plainText == decryptResult!!)
    }
}
