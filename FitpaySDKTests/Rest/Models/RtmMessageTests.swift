import XCTest
@testable import FitpaySDK

import UIKit

class RtmMessageTests: BaseTestProvider {

    func testResetDeviceResultParsing() {
        let rtmMessageResponse = mockModels.getRtmMessageResponse()

        XCTAssertEqual(rtmMessageResponse?.callBackId, 1)
        XCTAssertEqual(rtmMessageResponse?.type, mockModels.someType)
        XCTAssertEqual(rtmMessageResponse?.success, true)

        let json = rtmMessageResponse?.toJSON()
        XCTAssertEqual(json?["callBackId"] as? Int, 1)
        XCTAssertEqual(json?["type"] as? String, mockModels.someType)
        XCTAssertEqual(json?["isSuccess"] as? Bool, true)
    }

}
