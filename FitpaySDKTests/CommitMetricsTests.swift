//
//  CommitMetricsTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class CommitMetricsTests: BaseTestProvider {
        
    func testCommitMetricsParsing() {
        let commitMetrics = mockModels.getCommitMetrics()

        XCTAssertEqual(commitMetrics?.syncId, mockModels.someId)
        XCTAssertEqual(commitMetrics?.deviceId, mockModels.someId)
        XCTAssertEqual(commitMetrics?.userId, mockModels.someId)

        XCTAssertEqual(commitMetrics?.sdkVersion, "1")
        XCTAssertEqual(commitMetrics?.osVersion, "2")
        XCTAssertEqual(commitMetrics?.initiator, SyncInitiator(rawValue: "PLATFORM"))
        XCTAssertEqual(commitMetrics?.totalProcessingTimeMs, Int(mockModels.timeEpoch))
        XCTAssertNotNil(commitMetrics?.commitStatistics)

        let json = commitMetrics?.toJSON()
        XCTAssertEqual(json?["syncId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["deviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["userId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["sdkVersion"] as? String, "1")
        XCTAssertEqual(json?["osVersion"] as? String, "2")
        XCTAssertEqual(json?["initiator"] as? String, "PLATFORM")
        XCTAssertEqual(json?["totalProcessingTimeMs"] as? Int64, mockModels.timeEpoch)
        XCTAssertNotNil(json?["commits"])
    }
}
