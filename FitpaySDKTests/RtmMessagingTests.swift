import XCTest
@testable import FitpaySDK

class MockRtmMessageHandler: RtmMessageHandler {
    var a2aVerificationDelegate: FitpayA2AVerificationDelegate?
    
    weak var wvConfigStorage: WvConfigStorage!
    
    weak var outputDelegate: RtmOutputDelegate?
    weak var wvRtmDelegate: WvRTMDelegate?
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate?
    weak var cardScannerDataSource: FitpayCardScannerDataSource?
    
    var completion: ((_ message: [String: Any]) -> Void)?
    
    required init(wvConfigStorage: WvConfigStorage) {
        self.wvConfigStorage = wvConfigStorage
    }
    
    func handle(message: [String: Any]) {
        completion?(message)
    }
    
    func handlerFor(rtmMessage: RtmMessageType) -> MessageTypeHandler? {
        return nil
    }
    
    func handleSync(_ message: RtmMessage) {
        
    }
    func handleSessionData(_ message: RtmMessage) {
        
    }
    
    func resolveSync() {
        
    }
    
    func logoutResponseMessage() -> RtmMessageResponse? {
        return nil
    }
    
    func statusResponseMessage(message: String, type: WVMessageType) -> RtmMessageResponse? {
        return nil
    }
    
    func versionResponseMessage(version: RtmProtocolVersion) -> RtmMessageResponse? {
        return nil
    }
    
}

class RtmMessagingTests: XCTestCase {
    
    var rtmMessaging: RtmMessaging!
    let wvConfigStorage = WvConfigStorage()
    
    override func setUp() {
        super.setUp()
        
        rtmMessaging = RtmMessaging(wvConfigStorage: wvConfigStorage)
    }
    
    func testSuccessVersionNegotiating() {
        let expectation = super.expectation(description: "rtm messaging")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [RtmProtocolVersion.ver3: handler]
        
        handler.completion = { (_) in
            expectation.fulfill()
        }
        
        rtmMessaging.received(message: ["type":"version","callBackId":0,"data":["version":3]], completion: { (success) in
            XCTAssertTrue(success)
        })
        
        rtmMessaging.received(message: ["type":"ping","callBackId":1])
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnknownVersionReceived() {
        let expectation = super.expectation(description: "rtm messaging")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [RtmProtocolVersion.ver3: handler]
        
        rtmMessaging.received(message: ["type":"version","callBackId":0,"data":["version":99]], completion: { (success) in
            XCTAssertFalse(success)
        })
        
        rtmMessaging.received(message: ["type":"ping","callBackId":1], completion: { (success) in
            XCTAssertFalse(success)
            expectation.fulfill()
        })
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLowerVersionReceived() {
        let expectation = super.expectation(description: "rtm messaging")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [RtmProtocolVersion.ver2: handler,
                                        RtmProtocolVersion.ver3: MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)]
        
        handler.completion = { (_) in
            expectation.fulfill()
        }
        
        rtmMessaging.received(message: ["type":"version","callBackId":0,"data":["version":2]], completion: {
            XCTAssertTrue($0)
        })
        
        rtmMessaging.received(message: ["type":"ping","callBackId":1], completion: {
            XCTAssertTrue($0)
        })
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnknownMessageTypeNegotiating() {
        let expectation = super.expectation(description: "rtm messaging - unknown message type")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [RtmProtocolVersion.ver2: handler]
        
        handler.completion = { (message) in
            expectation.fulfill()
        }
        
        rtmMessaging.received(message: ["type":"UnknownType","callBackId":21,"data":["string parameter":"Some Details", "number parameter": 99]])
        
        rtmMessaging.received(message: ["type":"version","callBackId":0,"data":["version":2]], completion: { (success) in
            XCTAssertTrue(success)
        })
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
}
