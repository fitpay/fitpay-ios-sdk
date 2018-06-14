//
//  CreditCardTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class CreditCardTests: BaseTestProvider {
        
    func testCreditCardParsing() {
        let creditCard = mockModels.getCreditCard()

        XCTAssertNotNil(creditCard?.links)
        XCTAssertEqual(creditCard?.creditCardId, mockModels.someId)
        XCTAssertEqual(creditCard?.userId, mockModels.someId)
        XCTAssertEqual(creditCard?.isDefault, true)
        XCTAssertEqual(creditCard?.created, mockModels.someDate)
        XCTAssertEqual(creditCard?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(creditCard?.state, CreditCard.TokenizationState(rawValue: "NOT_ELIGIBLE"))
        XCTAssertEqual(creditCard?.cardType, mockModels.someType)
        XCTAssertNotNil(creditCard?.cardMetaData)
        XCTAssertEqual(creditCard?.termsAssetId, mockModels.someId)
        XCTAssertNotNil(creditCard?.termsAssetReferences)
        XCTAssertEqual(creditCard?.eligibilityExpiration, mockModels.someDate)
        XCTAssertNotNil(creditCard?.deviceRelationships)
        XCTAssertEqual(creditCard?.encryptedData, mockModels.someEncryptionData)
        XCTAssertEqual(creditCard?.targetDeviceId, mockModels.someId)
        XCTAssertEqual(creditCard?.targetDeviceType, mockModels.someType)
        XCTAssertNotNil(creditCard?.verificationMethods)
        XCTAssertEqual(creditCard?.externalTokenReference, "someToken")
        XCTAssertEqual(creditCard?.pan, "1234")
        XCTAssertEqual(creditCard?.expMonth, 12)
        XCTAssertEqual(creditCard?.expYear, 2018)
        XCTAssertEqual(creditCard?.cvv, "123")
        XCTAssertEqual(creditCard?.name, mockModels.someName)
        XCTAssertNotNil(creditCard?.address)
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
        XCTAssertNotNil(json?["deviceRelationships"])
        XCTAssertEqual(json?["encryptedData"] as? String, mockModels.someEncryptionData)
        XCTAssertEqual(json?["targetDeviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["targetDeviceType"] as? String, mockModels.someType)
        XCTAssertNotNil(json?["verificationMethods"])
        XCTAssertEqual(json?["externalTokenReference"] as? String, "someToken")
        XCTAssertEqual(json?["pan"] as? String, "1234")
        XCTAssertEqual(json?["expMonth"] as? Int64, 12)
        XCTAssertEqual(json?["expYear"] as? Int64, 2018)
        XCTAssertEqual(json?["cvv"] as? String, "123")
        XCTAssertEqual(json?["name"] as? String, mockModels.someName)
        XCTAssertNotNil(json?["address"])
        XCTAssertNotNil(json?["offlineSeActions.topOfWallet.apduCommands"])
    }
}
