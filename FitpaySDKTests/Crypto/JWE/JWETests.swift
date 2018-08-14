import XCTest
import Nimble

@testable import FitpaySDK

class JWETests: XCTestCase {
    let plainText = "{\"Hello world!\"}"
    let sharedSecret = "NFxCwmIncymviQp9-KKKgH_8McGHWGgwV-T-RNkMI-U".base64URLdecoded()
    
    func testJWEEncryption() {
        let jweObject = JWEObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: plainText, keyId: nil)
        expect(jweObject).toNot(beNil())
        
        guard let encryptResult = try? jweObject.encrypt(sharedSecret!) else {
            fail("Could Not Encrypt")
            return
        }
        
        expect(encryptResult).toNot(beNil())
        
        let jweResult = JWEObject(payload: encryptResult!)
        guard let decryptResult = try? jweResult.decrypt(sharedSecret!) else {
            fail("Could Not Deycrypt")
            return
        }
        
        expect(decryptResult).toNot(beNil())
        
        expect(decryptResult).to(equal(self.plainText))
    }
}
