
import XCTest

@testable import FitpaySDK

class RestSessionTests: XCTestCase {

    var session:RestSession!
    var client:RestClient!
    var testHelper:TestHelpers!
    let clientId = "pagare"
    let redirectUri = "https://demo.pagare.me"
    let password = "1029"
    
    override func setUp() {
        super.setUp()
        self.session = RestSession(clientId: self.clientId, redirectUri: self.redirectUri, authorizeURL: AUTHORIZE_URL, baseAPIURL: API_BASE_URL)
        self.client = RestClient(session: self.session!)
        self.testHelper = TestHelpers(clientId: clientId, redirectUri: redirectUri, session: self.session, client: self.client)
    }
    
    override func tearDown() {
        self.session = nil
        super.tearDown()
    }
    
    
    func testAcquireAccessTokenRetrievesToken() {
        let email = self.testHelper.randomEmail()
        let expectation = super.expectationWithDescription("'acquireAccessToken' retrieves auth details")

        self.client.createUser(
            email, password: self.password, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil,
            termsAccepted: nil, origin: nil, originAccountCreated: nil, completion:
        {
            (user, error) in

            XCTAssertNil(error)

            self.session.acquireAccessToken(
                clientId: self.clientId, redirectUri: self.redirectUri, username: email, password: self.password, completion:
            {
                authDetails, error in

                XCTAssertNotNil(authDetails)
                XCTAssertNil(error)
                XCTAssertNotNil(authDetails?.accessToken)

                expectation.fulfill()
            });
        })

        super.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testLoginRetrievesUserId() {
        let email = self.testHelper.randomEmail()
        let expectation = super.expectationWithDescription("'login' retrieves user id")

        self.client.createUser(
            email, password: self.password, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil,
            termsAccepted: nil, origin: nil, originAccountCreated: nil, completion:
        {
            (user, error) in

            self.session.login(username: email, password: self.password) {
                [unowned self]
                (error) -> Void in

                XCTAssertNil(error)
                XCTAssertNotNil(self.session.userId)

                expectation.fulfill()
            }
        })

        super.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testLoginFailsForWrongCredentials() {
        let expectation = super.expectationWithDescription("'login' fails for wrong credentials")
        
        self.session.login(username: "totally@wrong.abc", password:"fail") {
                [unowned self]
                (error) -> Void in
                
                XCTAssertNotNil(error)
                XCTAssertNil(self.session.userId)
                
                expectation.fulfill()
        }
        
        super.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
