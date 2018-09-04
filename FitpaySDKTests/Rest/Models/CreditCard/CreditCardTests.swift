import XCTest
import Nimble

@testable import FitpaySDK

class CreditCardTests: XCTestCase {
    let mockModels = MockModels()
        
    func testCreditCardParsing() {
        let creditCard = mockModels.getCreditCard()

        expect(creditCard?.creditCardId).to(equal(mockModels.someId))
        expect(creditCard?.userId).to(equal(mockModels.someId))
        expect(creditCard?.created).to(equal(mockModels.someDate))
        expect(creditCard?.createdEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(creditCard?.state).to(equal(TokenizationState.notEligible))
        expect(creditCard?.cardType).to(equal(mockModels.someType))
        expect(creditCard?.termsAssetId).to(equal(mockModels.someId))
        expect(creditCard?.eligibilityExpiration).to(equal(mockModels.someDate))
        expect(creditCard?.encryptedData).to(equal(mockModels.someEncryptionData))
        expect(creditCard?.targetDeviceId).to(equal(mockModels.someId))
        expect(creditCard?.targetDeviceType).to(equal(mockModels.someType))
        expect(creditCard?.externalTokenReference).to(equal("someToken"))
        
        expect(creditCard?.links).toNot(beNil())
        expect(creditCard?.cardMetaData).toNot(beNil())
        expect(creditCard?.termsAssetReferences).toNot(beNil())
        expect(creditCard?.verificationMethods).toNot(beNil())
        expect(creditCard?.topOfWalletAPDUCommands).toNot(beNil())


        let json = creditCard?.toJSON()
        expect(json?["creditCardId"] as? String).to(equal(mockModels.someId))
        expect(json?["createdTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["createdTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["state"] as? String).to(equal("NOT_ELIGIBLE"))
        expect(json?["cardType"] as? String).to(equal(mockModels.someType))
        expect(json?["termsAssetId"] as? String).to(equal(mockModels.someId))
        expect(json?["eligibilityExpiration"] as? String).to(equal(mockModels.someDate))
        expect(json?["eligibilityExpirationEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["encryptedData"] as? String).to(equal(mockModels.someEncryptionData))
        expect(json?["targetDeviceId"] as? String).to(equal(mockModels.someId))
        expect(json?["targetDeviceType"] as? String).to(equal(mockModels.someType))
        expect(json?["externalTokenReference"] as? String).to(equal("someToken"))
        
        expect(json?["_links"]).toNot(beNil())
        expect(json?["cardMetaData"]).toNot(beNil())
        expect(json?["termsAssetReferences"]).toNot(beNil())
        expect(json?["verificationMethods"]).toNot(beNil())
        expect(json?["offlineSeActions.topOfWallet.apduCommands"]).toNot(beNil())
    }
    
   
}
