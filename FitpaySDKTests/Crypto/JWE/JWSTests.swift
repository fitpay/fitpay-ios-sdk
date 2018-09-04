import XCTest
import Nimble

@testable import FitpaySDK

class JWSTests: XCTestCase {
    
    func testInitInvalidPartCount() {
        do {
            let _ = try JWS(token: "token.with.more.than.threeparts")
            fail("jws should fail with more than 3 parts")
        } catch let error {
            expect(error.localizedDescription).to(equal(JWTError.invalidPartCount.localizedDescription))
        }
    }
    
    func testInitInvalidBody() {
        do {
            let _ = try JWS(token: "eyJmb28iOiJiYXIifQ==.invalidbody.signature")
            fail("jws should fail with invalid body")
        } catch let error {
            expect(error.localizedDescription).to(equal(JWTError.invalidJSON.localizedDescription))
        }
    }
    
    func testInit() {
        let jws = try? JWS(token: "eyJmb28iOiJiYXIifQ==.eyJmb28iOiJiYXIifQ==.signature")
        expect(jws).toNot(beNil())
        expect(jws?.header).toNot(beNil())
        expect(jws?.body).toNot(beNil())
        expect(jws?.body["foo"] as? String).to(equal("bar"))
        expect(jws?.signature).to(equal("signature"))

    }
    
}
