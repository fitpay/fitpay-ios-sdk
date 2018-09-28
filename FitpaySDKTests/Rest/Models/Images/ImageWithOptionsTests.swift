import XCTest
import Nimble

@testable import FitpaySDK

class ImageWithOptionsTests: XCTestCase {
    
    private let mockModels = MockModels()
    private let mockRestRequest = MockRestRequest()
    private var session: RestSession?
    private var client: RestClient?
    
    override func setUp() {
        session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session!.accessToken = "authorized"
        
        client = RestClient(session: session!, restRequest: mockRestRequest)
    }
    
    func testRetrieveAssetWithNoClient() {
        let image = mockModels.getImageWithOptions()
        waitUntil { done in
            let imageAssetOptions = [ImageAssetOption.fontScale(10)]
            image?.retrieveAssetWith(options: imageAssetOptions) { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testRetrieveAssetWith() {
        let image = mockModels.getImageWithOptions()
        image?.client = client
        waitUntil { done in
            let imageAssetOptions = [ImageAssetOption.fontScale(10)]
            image?.retrieveAssetWith(options: imageAssetOptions) { (asset, error) in
                let urlString = try! self.mockRestRequest.lastUrl?.asURL().absoluteString

                expect(error).to(beNil())
                expect(asset).toNot(beNil())
                expect(urlString).to(contain("fs=10"))
                done()
            }
        }
    }
    
}
