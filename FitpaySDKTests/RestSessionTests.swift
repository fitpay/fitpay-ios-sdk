import XCTest
@testable import FitpaySDK

class RestSessionTests: XCTestCase {
    
    var session: MockRestSession!
    var client: MockRestClient!
    var testHelper: TestHelper!
    var clientId = "fp_webapp_pJkVp2Rl"
    let redirectUri = "https://webapp.fit-pay.com"
    let password = "1029"
    
    override func setUp() {
        super.setUp()
        
        self.session = MockRestSession()
        self.client =  MockRestClient(session: self.session!)
        self.testHelper = TestHelper(session: self.session, client: self.client)
    }
    
    override func tearDown() {
        self.session = nil
        super.tearDown()
    }
    
    func testAcquireAccessTokenRetrievesToken() {
        let email = TestHelper.randomEmail()
        let expectation = super.expectation(description: "'acquireAccessToken' retrieves auth details")
        
        self.client.createUser(email, password: self.password, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil, termsAccepted: nil, origin: nil, originAccountCreated: nil) { (user, error) in
                
                XCTAssertNil(error)
                
                self.session.acquireAccessToken(username: email, password: self.password) { authDetails, error in
                        
                        XCTAssertNotNil(authDetails)
                        XCTAssertNil(error)
                        XCTAssertNotNil(authDetails?.accessToken)
                        
                        expectation.fulfill()
                }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoginRetrievesUserId() {
        let email = TestHelper.randomEmail()
        let expectation = super.expectation(description: "'login' retrieves user id")
        
        self.client.createUser(
            email, password: self.password, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil,
            termsAccepted: nil, origin: nil, originAccountCreated: nil) { (user, error) in
                
                self.session.login(username: email, password: self.password) { [unowned self] (error) -> Void in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(self.session.userId)
                    
                    expectation.fulfill()
                }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testLoginFailsForWrongCredentials() {
        let expectation = super.expectation(description: "'login' fails for wrong credentials")
        
        self.session.login(username: "totally@wrong.abc", password: "fail") { [unowned self] (error) -> Void in
            
            XCTAssertNotNil(error)
            XCTAssertNil(self.session.userId)
            
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
}
