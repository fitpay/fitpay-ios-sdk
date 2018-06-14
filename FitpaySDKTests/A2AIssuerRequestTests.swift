//
//  A2AIssuerRequestTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class A2AIssuerRequestTests: BaseTestProvider {
        
    func testA2AIssuerRequestEncodingString() {
        let a2AIssuerRequest = A2AIssuerRequest(response: A2AIssuerRequest.A2AStepupResult.approved, authCode: "someCode")
        XCTAssertNotNil(a2AIssuerRequest.getEncodedString())
    }
}
