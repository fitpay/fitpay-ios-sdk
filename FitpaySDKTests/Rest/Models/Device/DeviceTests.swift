import XCTest
import Nimble

@testable import FitpaySDK

class DeviceTests: XCTestCase {
    let mockModels = MockModels()
    
    func testDeviceInfoParsing() {
        let deviceInfo = mockModels.getDeviceInfo()

        expect(deviceInfo?.links).toNot(beNil())
        expect(deviceInfo?.shortRTMRepersentation).toNot(beNil())

        expect(deviceInfo?.deviceIdentifier).to(equal(mockModels.someId))
        expect(deviceInfo?.deviceName).to(equal(mockModels.someName))
        expect(deviceInfo?.deviceType).to(equal(mockModels.someType))
        expect(deviceInfo?.manufacturerName).to(equal(mockModels.someName))
        expect(deviceInfo?.state).to(equal("12345fsd"))
        expect(deviceInfo?.serialNumber).to(equal("987654321"))
        expect(deviceInfo?.modelNumber).to(equal("1258PO"))
        expect(deviceInfo?.hardwareRevision).to(equal("12345fsd"))
        expect(deviceInfo?.firmwareRevision).to(equal("12345fsd"))
        expect(deviceInfo?.softwareRevision).to(equal("12345fsd"))
        expect(deviceInfo?.notificationToken).to(equal("12345fsd"))
        expect(deviceInfo?.createdEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(deviceInfo?.created).to(equal(mockModels.someDate))
        expect(deviceInfo?.osName).to(equal(mockModels.someName))
        expect(deviceInfo?.systemId).to(equal(mockModels.someId))
        expect(deviceInfo?.licenseKey).to(equal("147PLO"))
        expect(deviceInfo?.bdAddress).to(equal("someAddress"))
        expect(deviceInfo?.pairing).to(equal("pairing"))
        expect(deviceInfo?.secureElement?.secureElementId).to(equal(mockModels.someId))
        expect(deviceInfo?.secureElement?.casdCert).to(equal("casd"))
        expect(deviceInfo?.profileId).to(equal(mockModels.someId))
        expect(deviceInfo?.defaultCreditCardId).to(equal(mockModels.someId))

        let json = deviceInfo?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        
        expect(json?["deviceIdentifier"] as? String).to(equal(mockModels.someId))
        expect(json?["deviceName"] as? String).to(equal(mockModels.someName))
        expect(json?["deviceType"] as? String).to(equal(mockModels.someType))
        expect(json?["manufacturerName"] as? String).to(equal(mockModels.someName))
        expect(json?["state"] as? String).to(equal("12345fsd"))
        expect(json?["serialNumber"] as? String).to(equal("987654321"))
        expect(json?["modelNumber"] as? String).to(equal("1258PO"))
        expect(json?["hardwareRevision"] as? String).to(equal("12345fsd"))
        expect(json?["firmwareRevision"] as? String).to(equal("12345fsd"))
        expect(json?["softwareRevision"] as? String).to(equal("12345fsd"))
        expect(json?["notificationToken"] as? String).to(equal("12345fsd"))
        expect(json?["createdTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["createdTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["osName"] as? String).to(equal(mockModels.someName))
        expect(json?["systemId"] as? String).to(equal(mockModels.someId))
        expect(json?["licenseKey"] as? String).to(equal("147PLO"))
        expect(json?["bdAddress"] as? String).to(equal("someAddress"))
        expect(json?["pairing"] as? String).to(equal("pairing"))
        expect(json?["profileId"] as? String).to(equal(mockModels.someId))
        expect(json?["defaultCreditCardId"] as? String).to(equal(mockModels.someId))
        expect((json?["secureElement"] as? [String: Any])?["secureElementId"] as? String).to(equal(mockModels.someId))
        expect((json?["secureElement"] as? [String: Any])?["casdCert"] as? String).to(equal("casd"))
    }
    
    func testDefaultCreditCardAvailable() {
        let deviceInfo = mockModels.getDeviceInfo()
        let deviceInfoNoLinks = mockModels.getDeviceInfoNoLinks()
        
        let defaultCreditCardAvailable = deviceInfo?.defaultCreditCardAvailable
        expect(defaultCreditCardAvailable).to(beTrue())
        
        let defaultCreditCardNotAvailable = deviceInfoNoLinks?.defaultCreditCardAvailable
        expect(defaultCreditCardNotAvailable).to(beFalse())
    }
    
}
