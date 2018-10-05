import XCTest
import Nimble

@testable import FitpaySDK

class TermsAssetReferencesTests: XCTestCase {
    
    let mockModels = MockModels()
    
    func testtermsAssetReferenceParsing() {
        let terms = mockModels.getTermsAssetReferences()
        
        expect(terms?.mimeType).to(equal("text/html"))
        expect(terms?.links).toNot(beNil())
        
        let json = terms?.toJSON()
        expect(json?["mimeType"] as? String).to(equal("text/html"))
        expect(json?["_links"]).toNot(beNil())
        
    }
    
    func testRetrieveAssetNoClient() {
        let terms = mockModels.getTermsAssetReferences()
        waitUntil { done in
            terms?.retrieveAsset { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testRetrieveAsset() {
        let terms = mockModels.getTermsAssetReferences()
        let mockRestRequest = MockRestRequest()
        let session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session.accessToken = "authorized"
        
        let client = RestClient(session: session, restRequest: mockRestRequest)
        terms?.client = client
        
        waitUntil { done in
            terms?.retrieveAsset { (asset, error) in
                expect(error).to(beNil())
                expect(asset?.text).to(equal("html"))
                done()
            }
        }
        
    }
    
}
