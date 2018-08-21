import XCTest
@testable import FitpaySDK

fileprivate class MockModel: Serializable {
    var mockBoolArray: [Bool]?
    var mockDoubleArray: [Double]?
    var mockStringArray: [String]?
    var mockDeviceInfoArray: [Device]?
    var mockCreditCardArray: [CreditCard]?
    var mockTransactionArray: [Transaction]?
    var mockCommitArray: [Commit]?
    var mockUserArray: [User]?
    
    private enum CodingKeys: String, CodingKey {
        case boolArray
        case doubleArray
        case stringArray
        case deviceInfo
        case creditCard
        case transaction
        case commit
        case user
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mockBoolArray = try! container.decode([Bool].self, key: .boolArray)
        mockDoubleArray = try! container.decode([Double].self, key: .doubleArray)
        mockStringArray = try! container.decode([String].self, key: .stringArray)
        mockDeviceInfoArray = try! container.decode([Device].self, key: .deviceInfo)
        mockCreditCardArray = try! container.decode([CreditCard].self, forKey: .creditCard)
        mockTransactionArray = try! container.decode([Transaction].self, forKey: .transaction)
        mockCommitArray = try! container.decode([Commit].self, forKey: .commit)
        mockUserArray = try! container.decode([User].self, forKey: .user)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(mockBoolArray, key: .boolArray)
        try? container.encodeIfPresent(mockDoubleArray, key: .doubleArray)
        try? container.encodeIfPresent(mockStringArray, key: .stringArray)
        try? container.encodeIfPresent(mockDeviceInfoArray, forKey: .deviceInfo)
        try? container.encodeIfPresent(mockCreditCardArray, forKey: .creditCard)
        try? container.encodeIfPresent(mockTransactionArray, forKey: .transaction)
        try? container.encodeIfPresent(mockCommitArray, forKey: .commit)
        try? container.encodeIfPresent(mockUserArray, forKey: .user)
    }
}

class UnkeyedDecodingContainerTest: XCTestCase {
    let mockModels = MockModels()

    func testUnkeyed() {
        let bool = "true"
        let double = "2"
        let string = "\"some string\""
        let deviceInfo = mockModels.getDeviceInfo()?.toJSONString() ?? ""
        let creditCard = mockModels.getCreditCard()?.toJSONString() ?? ""
        let transaction = mockModels.getTransaction()?.toJSONString() ?? ""
        let commit = mockModels.getCommit()?.toJSONString() ?? ""
        let user = mockModels.getUser()?.toJSONString() ?? ""

        let mockModel = try? MockModel ("{\"boolArray\":[\(bool)], \"doubleArray\":[\(double)], \"stringArray\":[\(string)], \"deviceInfo\":[\(deviceInfo)], \"creditCard\":[\(creditCard)], \"transaction\":[\(transaction)], \"commit\":[\(commit)], \"user\":[\(user)]}")
        XCTAssertNotNil(mockModel?.mockBoolArray)
        XCTAssertNotNil(mockModel?.mockDoubleArray)
        XCTAssertNotNil(mockModel?.mockStringArray)
        XCTAssertNotNil(mockModel?.mockDeviceInfoArray)
        XCTAssertNotNil(mockModel?.mockTransactionArray)
        XCTAssertNotNil(mockModel?.mockCommitArray)
        XCTAssertNotNil(mockModel?.mockUserArray)

        let json = mockModel?.toJSON()
        XCTAssertNotNil((json?["boolArray"] as? [Any])?.first)
        XCTAssertNotNil((json?["doubleArray"] as? [Any])?.first)
        XCTAssertNotNil((json?["stringArray"] as? [Any])?.first)
        XCTAssertNotNil((json?["deviceInfo"] as? [Any])?.first)
        XCTAssertNotNil((json?["creditCard"] as? [Any])?.first)
        XCTAssertNotNil((json?["transaction"] as? [Any])?.first)
        XCTAssertNotNil((json?["commit"] as? [Any])?.first)
        XCTAssertNotNil((json?["user"] as? [Any])?.first)
    }
}
