import XCTest
import Nimble

@testable import FitpaySDK

class A2AIssuerResponseTests: BaseTestProvider {
        
    func testA2AIssuerRequestEncodingString() {
        let a2AIssuerRequest = A2AIssuerResponse(response: A2AIssuerResponse.A2AStepupResult.approved, authCode: "someCode")
        expect(a2AIssuerRequest.getEncodedString()).toNot(beNil())
    }
    
}
