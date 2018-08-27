import XCTest
@testable import FitpaySDK

class DeviceTests: XCTestCase {
    let mockModels = MockModels()
    
    func testDeviceInfoParsing() {
        let deviceInfo = mockModels.getDeviceInfo()

        XCTAssertNotNil(deviceInfo?.links)
        XCTAssertEqual(deviceInfo?.deviceIdentifier, mockModels.someId)
        XCTAssertEqual(deviceInfo?.deviceName, mockModels.someName)
        XCTAssertEqual(deviceInfo?.deviceType, mockModels.someType)
        XCTAssertEqual(deviceInfo?.manufacturerName, mockModels.someName)
        XCTAssertEqual(deviceInfo?.state, "12345fsd")
        XCTAssertEqual(deviceInfo?.serialNumber, "987654321")
        XCTAssertEqual(deviceInfo?.modelNumber, "1258PO")
        XCTAssertEqual(deviceInfo?.hardwareRevision, "12345fsd")
        XCTAssertEqual(deviceInfo?.firmwareRevision, "12345fsd")
        XCTAssertEqual(deviceInfo?.softwareRevision, "12345fsd")
        XCTAssertEqual(deviceInfo?.notificationToken, "12345fsd")
        XCTAssertEqual(deviceInfo?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(deviceInfo?.created, mockModels.someDate)
        XCTAssertEqual(deviceInfo?.osName, mockModels.someName)
        XCTAssertEqual(deviceInfo?.systemId, mockModels.someId)
        XCTAssertEqual(deviceInfo?.licenseKey, "147PLO")
        XCTAssertEqual(deviceInfo?.bdAddress, "someAddress")
        XCTAssertEqual(deviceInfo?.pairing, "pairing")
        XCTAssertEqual(deviceInfo?.secureElement?.secureElementId, mockModels.someId)
        XCTAssertEqual(deviceInfo?.secureElement?.casdCert, "casd")
        XCTAssertEqual(deviceInfo?.profileId, mockModels.someId)
        XCTAssertNotNil(deviceInfo?.shortRTMRepersentation)

        let json = deviceInfo?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["deviceIdentifier"] as? String, mockModels.someId)
        XCTAssertEqual(json?["deviceName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["deviceType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["manufacturerName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["state"] as? String, "12345fsd")
        XCTAssertEqual(json?["serialNumber"] as? String, "987654321")
        XCTAssertEqual(json?["modelNumber"] as? String, "1258PO")
        XCTAssertEqual(json?["hardwareRevision"] as? String, "12345fsd")
        XCTAssertEqual(json?["firmwareRevision"] as? String, "12345fsd")
        XCTAssertEqual(json?["softwareRevision"] as? String, "12345fsd")
        XCTAssertEqual(json?["notificationToken"] as? String, "12345fsd")
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["osName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["systemId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["licenseKey"] as? String, "147PLO")
        XCTAssertEqual(json?["bdAddress"] as? String, "someAddress")
        XCTAssertEqual(json?["pairing"] as? String, "pairing")
        XCTAssertEqual(json?["profileId"] as? String, mockModels.someId)
        XCTAssertEqual((json?["secureElement"] as? [String: Any])?["secureElementId"] as? String, mockModels.someId)
        XCTAssertEqual((json?["secureElement"] as? [String: Any])?["casdCert"] as? String, "casd")
    }
    
}