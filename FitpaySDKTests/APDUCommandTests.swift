//
//  APDUCommandTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class APDUCommandTests: BaseTestProvider {
        
    func testAPDUCommandParsing() {
        let apduCommand = mockModels.getApduCommand()

        XCTAssertNotNil(apduCommand?.links)
        XCTAssertEqual(apduCommand?.commandId, mockModels.someId)
        XCTAssertEqual(apduCommand?.groupId, 1)
        XCTAssertEqual(apduCommand?.sequence, 1)
        XCTAssertEqual(apduCommand?.command, "command")
        XCTAssertEqual(apduCommand?.type, mockModels.someType)
        XCTAssertEqual(apduCommand?.continueOnFailure, true)
        XCTAssertNotNil(apduCommand?.responseDictionary)

        let json = apduCommand?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["commandId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["groupId"] as? Int, 1)
        XCTAssertEqual(json?["sequence"] as? Int, 1)
        XCTAssertEqual(json?["command"] as? String, "command")
        XCTAssertEqual(json?["type"] as? String, mockModels.someType)
        XCTAssertEqual(json?["continueOnFailure"] as? Bool, true)
    }
}
