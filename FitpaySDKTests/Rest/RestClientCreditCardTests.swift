import XCTest
import Nimble

@testable import FitpaySDK

class RestClientCreditCardTests: XCTestCase {
    
    var session: RestSession!
    var client: RestClient!
    var testHelper: TestHelper!
    var clientId = "fp_webapp_pJkVp2Rl"
    let password = "1029"
    
    let restRequest = MockRestRequest()
    
    override func setUp() {
        super.setUp()
        
        session = RestSession(restRequest: restRequest)
        session.accessToken = "fakeToken"
        client =  RestClient(session: session!, restRequest: restRequest)
        
        testHelper = TestHelper(session: session, client: client)
        
        FitpayConfig.clientId = clientId
        FitpayConfig.apiURL = "https://api.fit-pay.com"
        FitpayConfig.authURL = "https://auth.fit-pay.com"
    }
    
    override func tearDown() {
        self.session = nil
        super.tearDown()
    }
    
    func testMakeDefaultWithDeviceId() {
        waitUntil { done in
            self.client.makeCreditCardDefault("https://baseurl.com/user/123/creditCards/456/makeDefault", deviceId: "123456") { (_, creditCard, error) in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString

                expect(error).to(beNil())
                expect(creditCard).toNot(beNil())
                expect(urlString).to(equal("https://baseurl.com/user/123/creditCards/456/makeDefault?deviceId=123456"))
                done()
            }
        }
    }
    
    func testMakeDefaultWithoutDeviceId() {
        waitUntil { done in
            self.client.makeCreditCardDefault("https://baseurl.com/user/123/creditCards/456/makeDefault", deviceId: nil) { (_, creditCard, error) in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString
                
                expect(error).to(beNil())
                expect(creditCard).toNot(beNil())
                expect(urlString).to(equal("https://baseurl.com/user/123/creditCards/456/makeDefault"))
                done()
            }
        }
    }
    
}
