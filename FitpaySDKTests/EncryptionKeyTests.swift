//
//  EncryptionKeyTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class EncryptionKeyTests: BaseTestProvider {
        
    func testEncryptionKeyParsing() {
        let encryptionKey = mockModels.getEncryptionKey()

        XCTAssertNotNil(encryptionKey?.links)
        XCTAssertEqual(encryptionKey?.keyId, mockModels.someId)
        XCTAssertEqual(encryptionKey?.created, mockModels.someDate)
        XCTAssertEqual(encryptionKey?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(encryptionKey?.expiration, mockModels.someDate)
        XCTAssertEqual(encryptionKey?.expirationEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(encryptionKey?.serverPublicKey, "someKey")
        XCTAssertEqual(encryptionKey?.clientPublicKey, "someKey")
        XCTAssertEqual(encryptionKey?.active, true)

        let json = encryptionKey?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["keyId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["expirationTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["expirationTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["serverPublicKey"] as? String, "someKey")
        XCTAssertEqual(json?["clientPublicKey"] as? String, "someKey")
        XCTAssertEqual(json?["active"] as? Bool, true)
    }

}
