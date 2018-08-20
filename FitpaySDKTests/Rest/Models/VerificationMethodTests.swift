import XCTest
@testable import FitpaySDK

class VerificationMethodTests: BaseTestProvider {
        
    func testVerificationMethodParsing() {
        let verificationMethod = mockModels.getVerificationMethod()

        XCTAssertNotNil(verificationMethod?.links)
        XCTAssertEqual(verificationMethod?.verificationId, mockModels.someId)
        XCTAssertEqual(verificationMethod?.state, VerificationState(rawValue: "AVAILABLE_FOR_SELECTION"))
        XCTAssertEqual(verificationMethod?.methodType, VerificationMethodType(rawValue: "TEXT_TO_CARDHOLDER_NUMBER"))
        XCTAssertEqual(verificationMethod?.value, "someValue")
        XCTAssertEqual(verificationMethod?.verificationResult, VerificationResult(rawValue: "SUCCESS"))
        XCTAssertEqual(verificationMethod?.created, mockModels.someDate)
        XCTAssertEqual(verificationMethod?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(verificationMethod?.lastModified, mockModels.someDate)
        XCTAssertEqual(verificationMethod?.lastModifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(verificationMethod?.verified, mockModels.someDate)
        XCTAssertEqual(verificationMethod?.verifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertNotNil(verificationMethod?.appToAppContext)

        let json = verificationMethod?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["verificationId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["state"] as? String, "AVAILABLE_FOR_SELECTION")
        XCTAssertEqual(json?["methodType"] as? String, "TEXT_TO_CARDHOLDER_NUMBER")
        XCTAssertEqual(json?["value"] as? String, "someValue")
        XCTAssertEqual(json?["verificationResult"] as? String, "SUCCESS")
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["lastModifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["lastModifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["verifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["verifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertNotNil(json?["appToAppContext"])
    }
}
