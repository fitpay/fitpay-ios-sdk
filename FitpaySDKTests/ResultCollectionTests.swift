//
//  ResultCollectionTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class ResultCollectionTests: BaseTestProvider {
        
    func testResultCollectionParsing() {
        let resultCollection = mockModels.getResultCollection()

        XCTAssertNotNil(resultCollection?.links)
        XCTAssertEqual(resultCollection?.limit, 1)
        XCTAssertEqual(resultCollection?.offset, 1)
        XCTAssertEqual(resultCollection?.totalResults, 1)
        XCTAssertNotNil(resultCollection?.results)

        let json = resultCollection?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["limit"] as? Int, 1)
        XCTAssertEqual(json?["offset"] as? Int, 1)
        XCTAssertEqual(json?["totalResults"] as? Int, 1)
    }
}
