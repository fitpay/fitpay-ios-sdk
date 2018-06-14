//
//  CardRelationshipTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class CardRelationshipTests: BaseTestProvider {
        
    func testCardRelationshipParsing() {
        let cardRelationship = mockModels.getCardRelationship()

        XCTAssertNotNil(cardRelationship?.links)
        XCTAssertEqual(cardRelationship?.creditCardId, mockModels.someId)
        XCTAssertEqual(cardRelationship?.pan, "1234")
        XCTAssertEqual(cardRelationship?.expMonth, 2)
        XCTAssertEqual(cardRelationship?.expYear, 2018)

        let cardRelationshipJson = cardRelationship?.toJSON()
        XCTAssertNotNil(cardRelationshipJson?["_links"])
        XCTAssertEqual(cardRelationshipJson?["creditCardId"] as? String, mockModels.someId)
        XCTAssertEqual(cardRelationshipJson?["pan"] as? String, "1234")
        XCTAssertEqual(cardRelationshipJson?["expMonth"] as? Int, 2)
        XCTAssertEqual(cardRelationshipJson?["expYear"] as? Int, 2018)
    }
}
