import XCTest
import Nimble

@testable import FitpaySDK

class CommitMetricsTests: XCTestCase {
    let mockModels = MockModels()
        
    func testCommitMetricsParsing() {
        let commitMetrics = mockModels.getCommitMetrics()

        expect(commitMetrics?.syncId).to(equal(mockModels.someId))
        expect(commitMetrics?.deviceId).to(equal(mockModels.someId))
        expect(commitMetrics?.userId).to(equal(mockModels.someId))

        expect(commitMetrics?.sdkVersion).to(equal("1"))
        expect(commitMetrics?.osVersion).to(equal("2"))
        expect(commitMetrics?.initiator).to(equal(SyncInitiator(rawValue: "PLATFORM")))
        expect(commitMetrics?.totalProcessingTimeMs).to(equal(Int(mockModels.timeEpoch)))
        expect(commitMetrics?.commitStatistics).toNot(beNil())

        let json = commitMetrics?.toJSON()
        expect(json?["syncId"] as? String).to(equal(mockModels.someId))
        expect(json?["deviceId"] as? String).to(equal(mockModels.someId))
        expect(json?["userId"] as? String).to(equal(mockModels.someId))
        expect(json?["sdkVersion"] as? String).to(equal("1"))
        expect(json?["osVersion"] as? String).to(equal("2"))
        expect(json?["initiator"] as? String).to(equal("PLATFORM"))
        expect(json?["totalProcessingTimeMs"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["commits"]).toNot(beNil())
    }
    
    func testInit() {
        let commitMetric = CommitMetrics()
        expect(commitMetric.sdkVersion).to(equal(FitpayConfig.sdkVersion))
        expect(commitMetric.osVersion).to(contain("iOS "))
    }
    
}
