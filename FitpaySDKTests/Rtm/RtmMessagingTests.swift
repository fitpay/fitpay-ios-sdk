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
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver3: handler]
        
        waitUntil { done in
            handler.completion = { (_) in
                done()
            }
            
            self.rtmMessaging.received(message: ["type": "version", "callBackId": 0,"data": ["version": 3]]) { (success) in
                expect(success).to(beTrue())
            }
            
            self.rtmMessaging.received(message: ["type": "ping", "callBackId": 1])
        }
    }
    
    func testUnknownVersionReceived() {        
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver3: handler]
        
        waitUntil { done in
            self.rtmMessaging.received(message: ["type": "version","callBackId": 0,"data": ["version": 99]]) { (success) in
                expect(success).to(beFalse())
            }
            
            self.rtmMessaging.received(message: ["type": "ping","callBackId": 1]) { (success) in
                expect(success).to(beFalse())
                done()
            }

        }
    }
    
    func testLowerVersionReceived() {
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver2: handler,
                                        WvConfig.RtmProtocolVersion.ver3: MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)]
        
        waitUntil { done in
            handler.completion = { (_) in
                done()
            }
            
            self.rtmMessaging.received(message: ["type": "version", "callBackId": 0,"data": ["version": 2]]) {
                expect($0).to(beTrue())
            }
            
            self.rtmMessaging.received(message: ["type": "ping", "callBackId": 1]) {
                expect($0).to(beTrue())
            }
        }
        
    }
    
    func testUnknownMessageTypeNegotiating() {
        let handler = MockRtmMessageHandler(wvConfigStorage: wvConfigStorage)
        rtmMessaging.handlersMapping = [WvConfig.RtmProtocolVersion.ver2: handler]
        
        
        waitUntil { done in
            handler.completion = { (_) in
                done()
            }
            
            self.rtmMessaging.received(message: ["type": "UnknownType", "callBackId": 21,"data": ["string parameter": "Some Details", "number parameter": 99]])
            
            self.rtmMessaging.received(message: ["type": "version", "callBackId": 0, "data": ["version": 2]]) { (success) in
                expect(success).to(beTrue())
            }
        }
    }
    
}
