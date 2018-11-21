import XCTest
import Nimble

@testable import FitpaySDK

class TransactionTests: XCTestCase {
    let mockModels = MockModels()

    func testTransactionParsing() {
        let transaction = mockModels.getTransaction()
        
        expect(transaction?.transactionId).to(equal("12345fsd"))
        expect(transaction?.transactionType).to(equal("someType"))
        expect(transaction?.amount).to(equal(3.22))
        expect(transaction?.currencyCode).to(equal("code"))
        expect(transaction?.authorizationStatus).to(equal("status"))
        expect(transaction?.transactionTime).to(equal("time"))
        expect(transaction?.transactionTimeEpoch).to(equal(1446587257))
        expect(transaction?.merchantName).to(equal("someName"))
        expect(transaction?.merchantCode).to(equal("code"))
        expect(transaction?.merchantType).to(equal("someType"))

        let json = transaction?.toJSON()
        expect(json).toNot(beNil())
        expect(json?["transactionId"] as? String).to(equal("12345fsd"))
        expect(json?["transactionType"] as? String).to(equal("someType"))
        expect(json?["amount"] as? String).to(equal("3.22"))
        expect(json?["currencyCode"] as? String).to(equal("code"))
        expect(json?["authorizationStatus"] as? String).to(equal("status"))
        expect(json?["transactionTime"] as? String).to(equal("time"))
        expect(json?["transactionTimeEpoch"] as? TimeInterval).to(equal(1446587257000))
        expect(json?["merchantName"] as? String).to(equal("someName"))
        expect(json?["merchantCode"] as? String).to(equal("code"))
        expect(json?["merchantType"] as? String).to(equal("someType"))

    }
    
    func testParsingDecimalValue() {
        let transaction = try? Transaction("{\"amount\": 0.691}")
        expect(transaction).toNot(beNil())
        expect(transaction!.amount?.description ?? "").to(equal("0.691"))
        
        let transaction2 = try? Transaction("{\"amount\": \"0.691\"}")
        expect(transaction2).toNot(beNil())
        expect(transaction2!.amount?.description ?? "").to(equal("0.691"))
    }
}
