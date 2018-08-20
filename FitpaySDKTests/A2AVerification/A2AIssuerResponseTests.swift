import XCTest
@testable import FitpaySDK

class A2AIssuerResponseTests: BaseTestProvider {
        
    func testA2AIssuerRequestEncodingString() {
        let a2AIssuerRequest = A2AIssuerResponse(response: A2AIssuerResponse.A2AStepupResult.approved, authCode: "someCode")
        XCTAssertNotNil(a2AIssuerRequest.getEncodedString())
    }
    
}
