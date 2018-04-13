import XCTest
import ObjectMapper

@testable import FitpaySDK

class IdVerificationResponseTests: XCTestCase {

    func testEmptyInitializerSetsLocale() {
        let verificationResponse = IdVerificationResponse()
        
        //locale is private so we will test the json output
        let verificationResonseJson = verificationResponse.toJSON()

        XCTAssertEqual(verificationResonseJson["locale"] as? String, "en-US")
    }
    
    func testLocaleNotOverridenWithJsonInitializer() {
        let verificationResponse = IdVerificationResponse(JSON: ["locale": "wrong"])
        
        //locale is private so we will test the json output
        XCTAssertNotNil(verificationResponse)
        let verificationResonseJson = verificationResponse!.toJSON()
        
        XCTAssertEqual(verificationResonseJson["locale"] as? String, "en-US")
    }

}
