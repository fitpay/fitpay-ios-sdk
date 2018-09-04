import XCTest
import Nimble

@testable import FitpaySDK

class RtmMessageTests: XCTestCase {
    let mockModels = MockModels()

    func testResetDeviceResultParsing() {
        let rtmMessageResponse = mockModels.getRtmMessageResponse()

        expect(rtmMessageResponse?.callBackId).to(equal(1))
        expect(rtmMessageResponse?.type).to(equal(mockModels.someType))
        expect(rtmMessageResponse?.success).to(equal(true))

        let json = rtmMessageResponse?.toJSON()
        expect(json?["callBackId"] as? Int).to(equal(1))
        expect(json?["type"] as? String).to(equal(mockModels.someType))
        expect(json?["isSuccess"] as? Bool).to(equal(true))
    }

}
