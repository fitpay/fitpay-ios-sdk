//
//  UsersTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class UsersTests: BaseTestProvider {
        
    func testUserParsing() {
        let user = mockModels.getUser()

        XCTAssertNotNil(user?.links)
        XCTAssertEqual(user?.id, mockModels.someId)
        XCTAssertEqual(user?.created, mockModels.someDate)
        XCTAssertEqual(user?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.lastModified, mockModels.someDate)
        XCTAssertEqual(user?.lastModifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.encryptedData, "some data")

        let json = user?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["id"] as? String, mockModels.someId)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["lastModifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["lastModifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["encryptedData"] as? String, "some data")
    }    
}
