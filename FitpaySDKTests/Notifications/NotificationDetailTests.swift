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
    
    func testNotificationDetailParsingOldSync() {
        let notificationDetail = mockModels.getNotificationDetailOld()
        
        expect(notificationDetail?.syncId).to(equal("12345fsd"))
        
        let json = notificationDetail?.toJSON()
        expect(json?["syncId"] as? String).to(equal("12345fsd"))
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
        expect(json?["syncId"] as? String).to(equal("12345fsd"))
        expect(json?["deviceId"] as? String).to(equal("12345fsd"))
        expect(json?["userId"] as? String).to(equal("12345fsd"))
        expect(json?["clientId"] as? String).to(equal("12345fsd"))
        expect(json?["creditCardId"] as? String).to(equal("12345fsd"))
    }
    
    func testSendAckSyncNoClient() {
        let notificationDetail = mockModels.getNotificationDetail()

        waitUntil { done in
            notificationDetail?.sendAckSync { (error) in
                expect(error).toNot(beNil())
                done()
            }
        }
    }
    
    func testSendAckSync() {
        let notificationDetail = mockModels.getNotificationDetail()
        notificationDetail?.client = restClient

        waitUntil { done in
            notificationDetail?.sendAckSync { (error) in
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testSendCompleteSyncNoClient() {
        let notificationDetail = mockModels.getNotificationDetail()
        let metrics = mockModels.getCommitMetrics()!
        
        waitUntil { done in
            notificationDetail?.sendCompleteSync(commitMetrics: metrics) { (error) in
                expect(error).toNot(beNil())
                done()
            }
        }
    }
    
    func testSendCompleteSync() {
        let notificationDetail = mockModels.getNotificationDetail()
        notificationDetail?.client = restClient
        let metrics = mockModels.getCommitMetrics()!
        
        waitUntil { done in
            notificationDetail?.sendCompleteSync(commitMetrics: metrics) { (error) in
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testGetCreditCardNoClient() {
        let notificationDetail = mockModels.getNotificationDetail()
        
        waitUntil { done in
            notificationDetail?.getCreditCard { (creditCard, error) in
                expect(creditCard).to(beNil())
                expect(error).toNot(beNil())
                done()
            }
        }
    }
    
    func testGetCreditCard() {
        let notificationDetail = mockModels.getNotificationDetail()
        notificationDetail?.client = restClient
        
        waitUntil { done in
            notificationDetail?.getCreditCard { (creditCard, error) in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString
                expect(urlString).to(equal("https://api.fit-pay.com/creditCards/12345fsd"))
                expect(creditCard).toNot(beNil())
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testGetDeviceNoClient() {
        let notificationDetail = mockModels.getNotificationDetail()
        
        waitUntil { done in
            notificationDetail?.getDevice { (device, error) in
                expect(device).to(beNil())
                expect(error).toNot(beNil())
                done()
            }
        }
    }
    
    func testGetDevice() {
        let notificationDetail = mockModels.getNotificationDetail()
        notificationDetail?.client = restClient
        
        waitUntil { done in
            notificationDetail?.getDevice { (device, error) in
                let urlString = try? self.restRequest.lastUrl?.asURL().absoluteString
                expect(urlString).to(equal("https://api.fit-pay.com/devices/12345fsd"))
                expect(device).toNot(beNil())
                expect(error).to(beNil())
                done()
            }
        }
    }
    
}
