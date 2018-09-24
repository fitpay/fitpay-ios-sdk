import XCTest
import Nimble

@testable import FitpaySDK

class VerificationMethodTests: XCTestCase {
    let mockModels = MockModels()
        
    func testVerificationMethodParsing() {
        let verificationMethod = mockModels.getVerificationMethod()

        expect(verificationMethod?.links).toNot(beNil())
        expect(verificationMethod?.verificationId).to(equal(mockModels.someId))
        expect(verificationMethod?.state).to(equal(VerificationState(rawValue: "AVAILABLE_FOR_SELECTION")))
        expect(verificationMethod?.methodType).to(equal(VerificationMethodType(rawValue: "TEXT_TO_CARDHOLDER_NUMBER")))
        expect(verificationMethod?.value).to(equal("someValue"))
        expect(verificationMethod?.verificationResult).to(equal(VerificationResult(rawValue: "SUCCESS")))
        expect(verificationMethod?.created).to(equal(mockModels.someDate))
        expect(verificationMethod?.createdEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(verificationMethod?.lastModified).to(equal(mockModels.someDate))
        expect(verificationMethod?.lastModifiedEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(verificationMethod?.verified).to(equal(mockModels.someDate))
        expect(verificationMethod?.verifiedEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(verificationMethod?.appToAppContext).toNot(beNil())

        let json = verificationMethod?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["verificationId"] as? String).to(equal(mockModels.someId))
        expect(json?["state"] as? String).to(equal("AVAILABLE_FOR_SELECTION"))
        expect(json?["methodType"] as? String).to(equal("TEXT_TO_CARDHOLDER_NUMBER"))
        expect(json?["value"] as? String).to(equal("someValue"))
        expect(json?["verificationResult"] as? String).to(equal("SUCCESS"))
        expect(json?["createdTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["lastModifiedTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["lastModifiedTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["verifiedTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["verifiedTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["appToAppContext"]).toNot(beNil())
    }

    func testSelectVerificationTypeNoClient() {
        let verificationMethod = mockModels.getVerificationMethod()
        
        verificationMethod?.selectVerificationType { (_, verificationMethod, error) in
            expect(verificationMethod).to(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testVerifyNoClient() {
        let verificationMethod = mockModels.getVerificationMethod()
        
        verificationMethod?.verify("verificationCode") { (_, verificationMethod, error) in
            expect(verificationMethod).to(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testRetrieveCreditCardNoClient() {
        let verificationMethod = mockModels.getVerificationMethod()
        
        verificationMethod?.retrieveCreditCard { (creditCard, error) in
            expect(creditCard).to(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testSelectAvailable() {
        let verificationMethod = mockModels.getVerificationMethod()
        let verificationMethodNoLinks = mockModels.getVerificationMethodWithoutLinks()
        
        let selectAvailable = verificationMethod?.selectAvailable
        expect(selectAvailable).to(beTrue())
        
        let selectNotAvailable = verificationMethodNoLinks?.selectAvailable
        expect(selectNotAvailable).toNot(beTrue())
    }
    
    func testVerifyAvailable() {
        let verificationMethod = mockModels.getVerificationMethod()
        let verificationMethodNoLinks = mockModels.getVerificationMethodWithoutLinks()
        
        let verifyAvailable = verificationMethod?.verifyAvailable
        expect(verifyAvailable).to(beTrue())
        
        let verifyNotAvailable = verificationMethodNoLinks?.verifyAvailable
        expect(verifyNotAvailable).toNot(beTrue())
    }
    
    func testCardAvailable() {
        let verificationMethod = mockModels.getVerificationMethod()
        let verificationMethodNoLinks = mockModels.getVerificationMethodWithoutLinks()

        let cardAvailable = verificationMethod?.cardAvailable
        expect(cardAvailable).to(beTrue())
        
        let cardNotAvailable = verificationMethodNoLinks?.cardAvailable
        expect(cardNotAvailable).toNot(beTrue())
    }
    
}
