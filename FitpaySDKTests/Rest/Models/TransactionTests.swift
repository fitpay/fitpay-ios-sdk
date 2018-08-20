import XCTest
@testable import FitpaySDK

class TransactionTests: XCTestCase {
    
    func testParsingDecimalValue() {
        let transaction = try? Transaction("{\"amount\": 0.691}")
        
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction!.amount?.description ?? "", "0.691")

        let json = transaction?.toJSON()
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["amount"] as? String, "0.691")
    }
}
