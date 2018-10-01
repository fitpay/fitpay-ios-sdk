import XCTest
import Nimble

@testable import FitpaySDK

class ImageTests: XCTestCase {
    
    private let mockModels = MockModels()
    private let mockRestRequest = MockRestRequest()
    private var session: RestSession?
    private var client: RestClient?
    
    override func setUp() {
        session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session!.accessToken = "authorized"
        
        client = RestClient(session: session!, restRequest: mockRestRequest)
    }
    
    func testImageParsing() {
        let image = mockModels.getImage()

        expect(image?.links).toNot(beNil())
        expect(image?.mimeType).to(equal("image/gif"))
        expect(image?.height).to(equal(20))
        expect(image?.width).to(equal(60))

        let json = image?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["mimeType"] as? String).to(equal("image/gif"))
        expect(json?["height"] as? Int).to(equal(20))
        expect(json?["width"] as? Int).to(equal(60))
    }
    
    func testRetrieveAssetNoClient() {
        let image = mockModels.getImage()
        waitUntil { done in
            image?.retrieveAsset { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testRetrieveAsset() {
        let image = mockModels.getImage()
        image?.client = client
        waitUntil { done in
            image?.retrieveAsset { (asset, error) in
                expect(error).to(beNil())
                expect(asset).toNot(beNil())
                done()
            }
        }
    }
    
}
