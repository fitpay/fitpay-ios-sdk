import XCTest
@testable import FitpaySDK

class CommitStatisticTests: XCTestCase {
    let mockModels = MockModels()
    
    func testCommitStatisticParsing() {
        let commitStatistic = mockModels.getCommitStatistic()

        XCTAssertEqual(commitStatistic?.commitId, mockModels.someId)
        XCTAssertEqual(commitStatistic?.processingTimeMs, Int(mockModels.timeEpoch))
        XCTAssertEqual(commitStatistic?.averageTimePerCommand, 3)
        XCTAssertEqual(commitStatistic?.errorReason, "bad access")

        let json = commitStatistic?.toJSON()
        XCTAssertEqual(json?["commitId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["processingTimeMs"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["averageTimePerCommand"] as? Int, 3)
        XCTAssertEqual(json?["errorReason"] as? String, "bad access")
    }
}
