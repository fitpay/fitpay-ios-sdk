import XCTest
@testable import FitpaySDK

class ApduPackageTests: BaseTestProvider {
        
    func testApduPackageParsing() {
        let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"

        let apduPackage = mockModels.getApduPackage()

        XCTAssertNotNil(apduPackage?.links)
        XCTAssertEqual(apduPackage?.seIdType, mockModels.someType)
        XCTAssertEqual(apduPackage?.targetDeviceType, mockModels.someType)
        XCTAssertEqual(apduPackage?.targetDeviceId, mockModels.someId)
        XCTAssertEqual(apduPackage?.packageId, mockModels.someId)
        XCTAssertEqual(apduPackage?.seId, mockModels.someId)
        XCTAssertNotNil(apduPackage?.apduCommands)
        XCTAssertEqual(apduPackage?.validUntil, mockModels.someDate)
        XCTAssertEqual(apduPackage?.validUntilEpoch, CustomDateFormatTransform(formatString: dateFormat).transform(mockModels.someDate))
        XCTAssertEqual(apduPackage?.apduPackageUrl, "www.example.com")
        XCTAssertNotNil(apduPackage?.responseDictionary)
        XCTAssertTrue(apduPackage?.isExpired ?? false)

        let json = apduPackage?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["seIdType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["targetDeviceType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["targetDeviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["packageId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["seId"] as? String, mockModels.someId)
        XCTAssertNotNil(json?["commandApdus"])
        XCTAssertEqual(json?["validUntil"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["apduPackageUrl"] as? String, "www.example.com")
    }

}
