import XCTest
@testable import FitpaySDK

class CreditCardTests: XCTestCase {
    let mockModels = MockModels()
        
    func testCreditCardParsing() {
        let creditCard = mockModels.getCreditCard()

        XCTAssertNotNil(creditCard?.links)
        XCTAssertEqual(creditCard?.creditCardId, mockModels.someId)
        XCTAssertEqual(creditCard?.userId, mockModels.someId)
        XCTAssertEqual(creditCard?.isDefault, true)
        XCTAssertEqual(creditCard?.created, mockModels.someDate)
        XCTAssertEqual(creditCard?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(creditCard?.state, TokenizationState.notEligible)
        XCTAssertEqual(creditCard?.cardType, mockModels.someType)
        XCTAssertNotNil(creditCard?.cardMetaData)
        XCTAssertEqual(creditCard?.termsAssetId, mockModels.someId)
        XCTAssertNotNil(creditCard?.termsAssetReferences)
        XCTAssertEqual(creditCard?.eligibilityExpiration, mockModels.someDate)
        XCTAssertEqual(creditCard?.encryptedData, mockModels.someEncryptionData)
        XCTAssertEqual(creditCard?.targetDeviceId, mockModels.someId)
        XCTAssertEqual(creditCard?.targetDeviceType, mockModels.someType)
        XCTAssertNotNil(creditCard?.verificationMethods)
        XCTAssertEqual(creditCard?.externalTokenReference, "someToken")
        XCTAssertNotNil(creditCard?.topOfWalletAPDUCommands)

        let json = creditCard?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["creditCardId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["default"] as? Bool, true)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["state"] as? String, "NOT_ELIGIBLE")
        XCTAssertEqual(json?["cardType"] as? String, mockModels.someType)
        XCTAssertNotNil(json?["cardMetaData"])
        XCTAssertEqual(json?["termsAssetId"] as? String, mockModels.someId)
        XCTAssertNotNil(json?["termsAssetReferences"])
        XCTAssertEqual(json?["eligibilityExpiration"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["eligibilityExpirationEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["encryptedData"] as? String, mockModels.someEncryptionData)
        XCTAssertEqual(json?["targetDeviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["targetDeviceType"] as? String, mockModels.someType)
        XCTAssertNotNil(json?["verificationMethods"])
        XCTAssertEqual(json?["externalTokenReference"] as? String, "someToken")
        XCTAssertNotNil(json?["offlineSeActions.topOfWallet.apduCommands"])
    }
}
