import XCTest
import Nimble

@testable import FitpaySDK

class CardMetaDataTests: XCTestCase {
    let mockModels = MockModels()
    
    func testCardInfoParsing() {
        let cardMetaData = mockModels.getCreditCardMetadata()
        
        expect(cardMetaData?.foregroundColor).to(equal("00000"))
        expect(cardMetaData?.issuerName).to(equal("someName"))
        expect(cardMetaData?.shortDescription).to(equal("Chase Freedom Visa"))
        expect(cardMetaData?.longDescription).to(equal("Chase Freedom Visa with the super duper rewards"))
        expect(cardMetaData?.contactUrl).to(equal("www.chase.com"))
        expect(cardMetaData?.contactPhone).to(equal("18001234567"))
        expect(cardMetaData?.contactEmail).to(equal("goldcustomer@chase.com"))
        expect(cardMetaData?.termsAndConditionsUrl).to(equal("http://visa.com/terms"))
        expect(cardMetaData?.privacyPolicyUrl).to(equal("http://visa.com/privacy"))
        expect(cardMetaData?.brandLogo?.count).to(equal(1))
        expect(cardMetaData?.cardBackground?.count).to(equal(1))
        expect(cardMetaData?.cardBackgroundCombined?.count).to(equal(1))
        expect(cardMetaData?.cardBackgroundCombinedEmbossed?.count).to(equal(1))
        expect(cardMetaData?.coBrandLogo?.count).to(equal(1))
        expect(cardMetaData?.icon?.count).to(equal(2))

        let json = cardMetaData?.toJSON()
        expect(json?["foregroundColor"] as? String).to(equal("00000"))
        expect(json?["issuerName"] as? String).to(equal("someName"))
        expect(json?["shortDescription"] as? String).to(equal("Chase Freedom Visa"))
        expect(json?["longDescription"] as? String).to(equal("Chase Freedom Visa with the super duper rewards"))
        expect(json?["contactUrl"] as? String).to(equal("www.chase.com"))
        expect(json?["contactPhone"] as? String).to(equal("18001234567"))
        expect(json?["contactEmail"] as? String).to(equal("goldcustomer@chase.com"))
        expect(json?["termsAndConditionsUrl"] as? String).to(equal("http://visa.com/terms"))
        expect(json?["privacyPolicyUrl"] as? String).to(equal("http://visa.com/privacy"))
        expect((json?["brandLogo"] as? [Any])?.count).to(equal(1))
        expect((json?["cardBackground"] as? [Any])?.count).to(equal(1))
        expect((json?["cardBackgroundCombined"] as? [Any])?.count).to(equal(1))
        expect((json?["cardBackgroundCombinedEmbossed"] as? [Any])?.count).to(equal(1))
        expect((json?["coBrandLogo"] as? [Any])?.count).to(equal(1))
        expect((json?["icon"] as? [Any])?.count).to(equal(2))

    }
    
    func testSetRestClient() {
        let cardMetaData = mockModels.getCreditCardMetadata()
        expect(cardMetaData?.client).to(beNil())
        expect(cardMetaData?.brandLogo?.first?.client).to(beNil())
        expect(cardMetaData?.cardBackground?.first?.client).to(beNil())
        expect(cardMetaData?.cardBackgroundCombined?.first?.client).to(beNil())
        expect(cardMetaData?.cardBackgroundCombinedEmbossed?.first?.client).to(beNil())
        expect(cardMetaData?.coBrandLogo?.first?.client).to(beNil())
        expect(cardMetaData?.icon?.first?.client).to(beNil())
        expect(cardMetaData?.icon?.last?.client).to(beNil())

        let restClient = RestClient(session: RestSession(sessionData: nil, restRequest: nil))
        cardMetaData?.client = restClient
        
        expect(cardMetaData?.client).to(equal(restClient))
        expect(cardMetaData?.brandLogo?.first?.client).to(equal(restClient))
        expect(cardMetaData?.cardBackground?.first?.client).to(equal(restClient))
        expect(cardMetaData?.cardBackgroundCombined?.first?.client).to(equal(restClient))
        expect(cardMetaData?.cardBackgroundCombinedEmbossed?.first?.client).to(equal(restClient))
        expect(cardMetaData?.coBrandLogo?.first?.client).to(equal(restClient))
        expect(cardMetaData?.icon?.first?.client).to(equal(restClient))
        expect(cardMetaData?.icon?.last?.client).to(equal(restClient))
        
    }
    
}
