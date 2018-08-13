import XCTest
@testable import FitpaySDK

class JWETests: XCTestCase {
    let plainText = "{\"Hello world!\"}"
    let sharedSecret = "NFxCwmIncymviQp9-KKKgH_8McGHWGgwV-T-RNkMI-U".base64URLdecoded()
    
    func testJWEEncryption() {
        let jweObject = JWEObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: plainText, keyId: nil)
        XCTAssertNotNil(jweObject)
        
        guard let encryptResult = try? jweObject.encrypt(sharedSecret!) else {
            XCTFail("Could Not Encrypt")
            return
        }
        
        XCTAssertNotNil(encryptResult)
        
        let jweResult = JWEObject(payload: encryptResult!)
        guard let decryptResult = try? jweResult.decrypt(sharedSecret!) else {
            XCTFail("Could Not Deycrypt")
            return
        }
        
        XCTAssertNotNil(decryptResult)
        
        XCTAssertTrue(plainText == decryptResult)
    }
}
