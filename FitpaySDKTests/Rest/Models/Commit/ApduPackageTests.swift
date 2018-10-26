import XCTest
import Nimble

@testable import FitpaySDK

class ApduPackageTests: XCTestCase {
    let mockModels = MockModels()
        
    func testApduPackageParsing() {
        let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"

        let apduPackage = mockModels.getApduPackage()

        expect(apduPackage?.seIdType).to(equal(mockModels.someType))
        expect(apduPackage?.targetDeviceType).to(equal(mockModels.someType))
        expect(apduPackage?.targetDeviceId).to(equal(mockModels.someId))
        expect(apduPackage?.packageId).to(equal(mockModels.someId))
        expect(apduPackage?.seId).to(equal(mockModels.someId))
        expect(apduPackage?.apduCommands).toNot(beNil())
        expect(apduPackage?.validUntil).to(equal(mockModels.someDate))
        expect(apduPackage?.validUntilEpoch).to(equal(CustomDateFormatTransform(formatString: dateFormat).transform(mockModels.someDate)))
        expect(apduPackage?.apduPackageUrl).to(equal("www.example.com"))
        expect(apduPackage?.responseDictionary).toNot(beNil())
        expect(apduPackage?.isExpired).to(beTrue())

        let json = apduPackage?.toJSON()
        expect(json?["seIdType"] as? String).to(equal(mockModels.someType))
        expect(json?["targetDeviceType"] as? String).to(equal(mockModels.someType))
        expect(json?["targetDeviceId"] as? String).to(equal(mockModels.someId))
        expect(json?["packageId"] as? String).to(equal(mockModels.someId))
        expect(json?["seId"] as? String).to(equal(mockModels.someId))
        expect(json?["commandApdus"]).toNot(beNil())
        expect(json?["validUntil"] as? String).to(equal(mockModels.someDate))
        expect(json?["apduPackageUrl"] as? String).to(equal("www.example.com"))

    }
    
    func testIsExpiredNoValid() {
        let apduPackage = mockModels.getApduPackage()
        apduPackage?.validUntilEpoch = nil
        expect(apduPackage?.isExpired).to(beFalse())
    }
    
    func testResponseDictionary() {
        let apduPackage = ApduPackage()
        apduPackage.packageId = "packageId"
        apduPackage.state = APDUPackageResponseState.failed
        apduPackage.executedEpoch = 1
        apduPackage.executedDuration = 2
        
        let responseDict = apduPackage.responseDictionary
        expect(responseDict["packageId"] as? String).to(equal("packageId"))
        expect(responseDict["state"] as? String).to(equal("FAILED"))
        expect(responseDict["executedTsEpoch"] as? Int64).to(equal(1000)) // fails as int
        expect(responseDict["executedDuration"] as? Int).to(equal(2))
        expect(responseDict["apduResponses"]).to(beNil())
    }

}
