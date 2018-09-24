import XCTest
import Nimble

@testable import FitpaySDK

class RestSessionTests: XCTestCase {
    
    var session: RestSession!
    var client: RestClient!
    var testHelper: TestHelper!
    var clientId = "fp_webapp_pJkVp2Rl"
    let password = "1029"
    
    let restRequest = MockRestRequest()
    
    override func setUp() {
        super.setUp()

        session = RestSession(restRequest: restRequest)
        self.client =  RestClient(session: self.session!, restRequest: restRequest)
        self.testHelper = TestHelper(session: self.session, client: self.client)
        
        FitpayConfig.clientId = clientId
        FitpayConfig.apiURL = "https://api.fit-pay.com"
        FitpayConfig.authURL = "https://auth.fit-pay.com"
    }
    
    override func tearDown() {
        self.session = nil
        super.tearDown()
    }
    
    func testLoginRetrievesUserId() {
        let email = TestHelper.getEmail()
        
        waitUntil { done in
            self.client.createUser(email, password: self.password, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil, termsAccepted: nil, origin: nil, originAccountCreated: nil) { (_, error) in
                self.session.login(username: email, password: self.password) { [unowned self] (error) -> Void in
                    expect(error).to(beNil())
                    expect(self.session.userId).toNot(beNil())
                    done()
                }
            }
        }        
    }
    
}
