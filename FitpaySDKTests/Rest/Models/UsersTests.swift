import XCTest
import Alamofire

@testable import FitpaySDK

class UsersTests: XCTestCase {
    let mockModels = MockModels()
    
    var user: User!
    var restClient: RestClient!
    var testHelper: TestHelper!
    
    let restRequest = MockRestRequest()
    
    override func setUp() {
        let session = RestSession(restRequest: restRequest)
        restClient = RestClient(session: session, restRequest: restRequest)
        testHelper = TestHelper(session: session, client: restClient)
        
        FitpayConfig.clientId = "fp_webapp_pJkVp2Rl"
    
        let expectation = self.expectation(description: "setUp")

        testHelper.createAndLoginUser(expectation) { [unowned self] user in
            self.user = user
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    override func tearDown() {
        let expectation = self.expectation(description: "tearDown")

        user.deleteUser { (error) in
            if error != nil {
                XCTFail("error deleting user")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testUserParsing() {
        let user = mockModels.getUser()

        XCTAssertNotNil(user?.links)
        XCTAssertEqual(user?.id, mockModels.someId)
        XCTAssertEqual(user?.created, mockModels.someDate)
        XCTAssertEqual(user?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.lastModified, mockModels.someDate)
        XCTAssertEqual(user?.lastModifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.encryptedData, "some data")

        let json = user?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["id"] as? String, mockModels.someId)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["lastModifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["lastModifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["encryptedData"] as? String, "some data")
    }
    
    func testGetCreditCardsWithDeviceId() {
        let expectation = self.expectation(description: "getCreditCards")
        
        user?.getCreditCards(excludeState: [], limit: 10, offset: 0, deviceId: "1234") { (creditCardCollection, error) in
            XCTAssertEqual(self.restRequest.lastParams?["deviceId"] as? String, "1234")
            let lastEncodingAsURL = self.restRequest.lastEncoding as? URLEncoding
            XCTAssertNotNil(lastEncodingAsURL)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testCreateCreditCardsWithDeviceId() {
        let expectation = self.expectation(description: "createCreditCard")
        
        let address = Address(street1: "123 Lane", street2: nil, street3: nil, city: "Boulder", state: "Colorado", postalCode: "80401", countryCode: nil)
        let creditCardInfo = CardInfo(pan: "123456", expMonth: 12, expYear: 2020, cvv: "123", name: "Jeremiah Harris", address: address, riskData: nil)
        
        user.createCreditCard(cardInfo: creditCardInfo, deviceId: "1234") { (creditCard, error) in
            XCTAssertEqual(self.restRequest.lastParams?["deviceId"] as? String, "1234")
            let lastEncodingAsJson = self.restRequest.lastEncoding as? JSONEncoding
            XCTAssertNotNil(lastEncodingAsJson)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
}
