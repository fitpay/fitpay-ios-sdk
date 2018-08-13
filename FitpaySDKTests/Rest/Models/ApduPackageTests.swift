import XCTest
import Nimble

@testable import FitpaySDK

class ApduPackageTests: BaseTestProvider {
        
    func testApduPackageParsing() {
        let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"

        let apduPackage = mockModels.getApduPackage()

        expect(apduPackage?.links).toNot(beNil())
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
        expect(json?["_links"]).toNot(beNil())
        expect(json?["seIdType"] as? String).to(equal(mockModels.someType))
        expect(json?["targetDeviceType"] as? String).to(equal(mockModels.someType))
        expect(json?["targetDeviceId"] as? String).to(equal(mockModels.someId))
        expect(json?["packageId"] as? String).to(equal(mockModels.someId))
        expect(json?["seId"] as? String).to(equal(mockModels.someId))
        expect(json?["commandApdus"]).toNot(beNil())
        expect(json?["validUntil"] as? String).to(equal(mockModels.someDate))
        expect(json?["apduPackageUrl"] as? String).to(equal("www.example.com"))

    }

}
