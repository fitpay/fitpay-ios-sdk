import XCTest
@testable import FitpaySDK

class TransactionTests: XCTestCase {
    
    func testParsingDecimalValue() {
        let json = "{\"amount\": 0.691}"
        let transaction = Transaction(JSONString: json)
        
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction!.amount?.description ?? "", "0.691")
    }
}
