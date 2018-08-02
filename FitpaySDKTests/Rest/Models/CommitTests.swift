import XCTest
@testable import FitpaySDK

class CommitTests: BaseTestProvider {
        
    func testCommitParsing() {
        let commit = mockModels.getCommit()

        XCTAssertNotNil(commit?.links)
        XCTAssertEqual(commit?.commitTypeString, mockModels.someType)
        XCTAssertEqual(commit?.created, CLong(mockModels.timeEpoch))
        XCTAssertEqual(commit?.previousCommit, "2")
        XCTAssertEqual(commit?.commitId, mockModels.someId)
        XCTAssertEqual(commit?.encryptedData, mockModels.someEncryptionData)

        let json = commit?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["commitType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["createdTs"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["previousCommit"] as? String, "2")
        XCTAssertEqual(json?["commitId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["encryptedData"] as? String, mockModels.someEncryptionData)
    }
}
