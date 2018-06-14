//
//  RelationshipTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class RelationshipTests: BaseTestProvider {
        
    func testRelationshipParsing() {
        let relationship = mockModels.getRelationship()

        XCTAssertNotNil(relationship?.links)
        XCTAssertNotNil(relationship?.card)
        XCTAssertNotNil(relationship?.device)

        let json = relationship?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertNotNil(json?["card"])
        XCTAssertNotNil(json?["device"])
    }
}
