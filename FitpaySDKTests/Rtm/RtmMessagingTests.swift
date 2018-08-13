import XCTest
import Nimble

@testable import FitpaySDK

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
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver3: handler]
        
        handler.completion = { (_) in
            expectation.fulfill()
        }
        
        rtmMessaging.received(message: ["type":"version","callBackId": 0,"data": ["version": 3]]) { (success) in
            expect(success).to(beTrue())
        }
        
        rtmMessaging.received(message: ["type": "ping","callBackId": 1])
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnknownVersionReceived() {
        let expectation = super.expectation(description: "rtm messaging")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver3: handler]
        
        rtmMessaging.received(message: ["type": "version","callBackId": 0,"data": ["version": 99]]) { (success) in
            XCTAssertFalse(success)
        }
        
        rtmMessaging.received(message: ["type": "ping","callBackId": 1]) { (success) in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLowerVersionReceived() {
        let expectation = super.expectation(description: "rtm messaging")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver2: handler,
                                        WvConfig.RtmProtocolVersion.ver3: MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)]
        
        handler.completion = { (_) in
            expectation.fulfill()
        }
        
        rtmMessaging.received(message: ["type": "version", "callBackId": 0,"data": ["version": 2]]) {
            expect($0).to(beTrue())
        }
        
        rtmMessaging.received(message: ["type": "ping", "callBackId": 1]) {
            expect($0).to(beTrue())
        }
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnknownMessageTypeNegotiating() {
        let expectation = super.expectation(description: "rtm messaging - unknown message type")
        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver2: handler]
        
        handler.completion = { (message) in
            expectation.fulfill()
        }
        
        rtmMessaging.received(message: ["type": "UnknownType", "callBackId": 21,"data": ["string parameter": "Some Details", "number parameter": 99]])
        
        rtmMessaging.received(message: ["type": "version", "callBackId": 0, "data": ["version": 2]]) { (success) in
            expect(success).to(beTrue())
        }
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
}
