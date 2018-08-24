import XCTest
import Nimble

@testable import FitpaySDK

class NotificationDetailTests: XCTestCase {
    let mockModels = MockModels()
    let restRequest = MockRestRequest()

    var restClient: RestClient?
    
    override func setUp() {
        super.setUp()
        
        let session = RestSession(restRequest: restRequest)
        session.accessToken = "fakeToken"
        
        restClient = RestClient(session: session, restRequest: restRequest)
    }
    
    func testNotificationDetailParsing() {
        let notificationDetail = mockModels.getNotificationDetail()
        expect(notificationDetail?.type).to(equal("someType"))
        expect(notificationDetail?.syncId).to(equal("12345fsd"))
        expect(notificationDetail?.deviceId).to(equal("12345fsd"))
        expect(notificationDetail?.userId).to(equal("12345fsd"))
        expect(notificationDetail?.clientId).to(equal("12345fsd"))
        expect(notificationDetail?.creditCardId).to(equal("12345fsd"))
        
        let json = notificationDetail?.toJSON()
        expect(json?["type"] as? String).to(equal("someType"))
        expect(json?["id"] as? String).to(equal("12345fsd"))
        expect(json?["deviceId"] as? String).to(equal("12345fsd"))
        expect(json?["userId"] as? String).to(equal("12345fsd"))
        expect(json?["clientId"] as? String).to(equal("12345fsd"))
        expect(json?["creditCardId"] as? String).to(equal("12345fsd"))
        
    }
    
    func testGetCreditCard() {
        let notificationDetail = mockModels.getNotificationDetail()
        notificationDetail?.client = restClient
        
        waitUntil { done in
            notificationDetail?.getCreditCard() { (creditCard, error) in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString
                expect(urlString).to(equal("https://api.fit-pay.com/creditCards/12345fsd"))
                expect(creditCard).toNot(beNil())
                expect(error).to(beNil())
                done()
            }
        }
        
    }
    
}




