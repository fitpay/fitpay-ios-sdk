import XCTest
import Nimble

@testable import FitpaySDK

class ResetDeviceResultTests: XCTestCase {
    
    let mockModels = MockModels()

    func testResetDeviceResultParsing() {
        let resetDeviceResultParsing = mockModels.getResetDeviceResult()

        expect(resetDeviceResultParsing?.resetId).to(equal("464c0897-dd8a-45d5-bc5b-5592cddb363e"))
        expect(resetDeviceResultParsing?.status).to(equal(DeviceResetStatus(rawValue: "IN_PROGRESS")))
        expect(resetDeviceResultParsing?.seStatus).to(equal(DeviceResetStatus(rawValue: "IN_PROGRESS")))
        expect(resetDeviceResultParsing?.links?.count).to(equal(1))

        let json = resetDeviceResultParsing?.toJSON()
        expect(json?["resetId"] as? String).to(equal("464c0897-dd8a-45d5-bc5b-5592cddb363e"))
        expect(json?["status"] as? String).to(equal("IN_PROGRESS"))
        expect(json?["seStatus"] as? String).to(equal("IN_PROGRESS"))

    }
}
