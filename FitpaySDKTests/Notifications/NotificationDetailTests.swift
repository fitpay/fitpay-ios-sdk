import XCTest
import Nimble

@testable import FitpaySDK

class NotificationDetailTests: XCTestCase {
    let mockModels = MockModels()
    
    func testNotificationDetailParsing() {
        let notificationDetail = mockModels.getNotificationDetail()
        expect(notificationDetail?.type).to(equal("someType"))
        expect(notificationDetail?.syncId).to(equal("12345fsd"))
        expect(notificationDetail?.deviceId).to(equal("12345fsd"))
        expect(notificationDetail?.userId).to(equal("12345fsd"))
        expect(notificationDetail?.clientId).to(equal("12345fsd"))
        expect(notificationDetail?.cardId).to(equal("12345fsd"))
        
        let json = notificationDetail?.toJSON()
        expect(json?["type"] as? String).to(equal("someType"))
        expect(json?["id"] as? String).to(equal("12345fsd"))
        expect(json?["deviceId"] as? String).to(equal("12345fsd"))
        expect(json?["userId"] as? String).to(equal("12345fsd"))
        expect(json?["clientId"] as? String).to(equal("12345fsd"))
        expect(json?["cardId"] as? String).to(equal("12345fsd"))
        
    }
    
/* TODO make this work - failing authorization key exchange - nth: better error messages around auth failures on tests
    func testGetCreditCard() {
        let restRequest = MockRestRequest()
        let notificationDetail = mockModels.getNotificationDetail()
        let session = RestSession(restRequest: restRequest)
        let restClient = RestClient(session: session, restRequest: restRequest)
        
        notificationDetail?.client = restClient
        
        waitUntil { done in
            notificationDetail?.getCreditCard() { (creditCard, error) in
                let urlString = try? restRequest.lastUrl?.asURL().absoluteString
                print("restRequest.lastUrl:  \(restRequest.lastUrl)")
                expect(urlString).to(equal("https://api.fit-pay.com/creditCards/12345fsd"))
                done()
            }
        }
        
    }
 */
    
}




