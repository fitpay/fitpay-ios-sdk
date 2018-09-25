import XCTest
import Nimble

@testable import FitpaySDK

class JWTUtilsTests: XCTestCase {
    
    func testdecodeJWTPartInvalidJSON() {
        do {
            _ = try JWTUtils.decodeJWTPart("notjson")
            fail("jws should fail with invalidJSON")
        } catch let error {
            expect(error.localizedDescription).to(equal(JWTError.invalidJSON.localizedDescription))
        }
    }
    
    func testdecodeJWTPartInvaliBas64URL() {
        do {
            _ = try JWTUtils.decodeJWTPart("eyJmb28iO +_-iJiYXIifQ==")
            fail("decodeJWTPart should fail with invalidBase64Url")
        } catch let error {
            expect(error.localizedDescription).to(equal(JWTError.invalidBase64Url.localizedDescription))
        }
    }
    
    func testdecodeJWTPart() {
        let decoded = try? JWTUtils.decodeJWTPart("eyJmb28iOiJiYXIifQ==")
        expect(decoded).toNot(beNil())
        expect(decoded?["foo"] as? String).to(equal("bar"))
    }
    
}
