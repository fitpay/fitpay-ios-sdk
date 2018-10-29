import XCTest
import Nimble
import Alamofire

@testable import FitpaySDK

class RestSessionTests: XCTestCase {
    
    var session: RestSession!
    var client: RestClient!
    var testHelper: TestHelper!
    var clientId = "fp_webapp_pJkVp2Rl"
    
    let restRequest = MockRestRequest()
    
    override func setUp() {
        super.setUp()
        
        session = RestSession(restRequest: restRequest)
        
        FitpayConfig.clientId = clientId
        FitpayConfig.apiURL = "https://api.fit-pay.com"
        FitpayConfig.authURL = "https://auth.fit-pay.com"
    }
    
    override func tearDown() {
        session = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInit() {
        let sessionOne = RestSession()
        expect(sessionOne.userId).to(beNil())
        expect(sessionOne.accessToken).to(beNil())
        
        let sessionData = SessionData(token: "token", userId: "userId", deviceId: "deviceId")
        let sessionTwo = RestSession(sessionData: sessionData)
        expect(sessionTwo.userId).to(equal("userId"))
        expect(sessionTwo.accessToken).to(equal("token"))
        
    }
    
    func testIsAuthorized() {
        session.accessToken = nil
        expect(self.session.isAuthorized).to(beFalse())
        
        session.accessToken = "token"
        expect(self.session.isAuthorized).to(beTrue())
    }
    
    func testSetWebViewAuthorization() {
        session.accessToken = nil
        session.userId = nil
        
        let sessionData = SessionData(token: "token", userId: "userId", deviceId: "deviceId")
        session.setWebViewAuthorization(sessionData)
        
        expect(self.session.userId).to(equal("userId"))
        expect(self.session.accessToken).to(equal("token"))
    }
    
    func testLoginWithUserNamePassword() {
        let email = "test@test.com"
        let password = "9000"
        
        waitUntil { done in
            self.session.login(username: email, password: password) { [unowned self] (error) -> Void in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString
                let lastEncodingAsUrl = self.restRequest.lastEncoding as? URLEncoding
                
                expect(error).to(beNil())
                expect(self.session.userId).toNot(beNil())
                expect(urlString).to(equal("https://auth.fit-pay.com/oauth/authorize"))
                expect(lastEncodingAsUrl).toNot(beNil())
                expect(self.restRequest.lastParams?["credentials"] as? String).to(contain("\"username\":\"test@test.com\""))
                expect(self.restRequest.lastParams?["credentials"] as? String).to(contain("\"password\":\"9000\""))

                done()
            }
        }
    }
    
    func testLoginFirebase() {        
        waitUntil { done in
            self.session.login(firebaseToken: "123") { (error) in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString
                let lastEncodingAsUrl = self.restRequest.lastEncoding as? URLEncoding
                
                expect(error).to(beNil())
                expect(self.session.userId).toNot(beNil())
                expect(urlString).to(equal("https://auth.fit-pay.com/oauth/token"))
                expect(lastEncodingAsUrl).toNot(beNil())
                expect(self.restRequest.lastParams?["firebase_token"] as? String).to(equal("123"))
                done()
            }
        }
    }
    
    func testErrorCodeDescription() {
        expect(RestSession.ErrorCode.unknownError.description).to(equal("Unknown error"))
        expect(RestSession.ErrorCode.deviceNotFound.description).to(equal("Can't find device provided by wv."))
        expect(RestSession.ErrorCode.userOrDeviceEmpty.description).to(equal("User or device empty."))
    }
    
}
