//
//  IssuersTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class IssuersTests: BaseTestProvider {
        
    func testIssuersParsing() {
        let issuers = mockModels.getIssuers()

        XCTAssertNotNil(issuers?.links)
        XCTAssertNotNil(issuers?.countries)

        let json = issuers?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertNotNil(json?["countries"])
    }
}
