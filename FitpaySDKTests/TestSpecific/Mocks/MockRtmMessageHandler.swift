import XCTest

@testable import FitpaySDK

class MockRtmMessageHandler: RtmMessageHandler {
    
    var a2aVerificationDelegate: FitpayA2AVerificationDelegate?
    
    var wvConfigStorage: WvConfigStorage!
    
    weak var outputDelegate: RtmOutputDelegate?
    weak var wvRtmDelegate: RTMDelegate?
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate?
    weak var cardScannerDataSource: FitpayCardScannerDataSource?
    
    var completion: ((_ message: [String: Any]) -> Void)?
    
    required init(wvConfigStorage: WvConfigStorage) {
        self.wvConfigStorage = wvConfigStorage
    }
    
    func handle(message: [String: Any]) {
        completion?(message)
    }
    
    func handlerFor(rtmMessage: String) -> MessageTypeHandler? {
        return nil
    }
    
    func handleSync(_ message: RtmMessage) {
        
    }
    
    func handleSessionData(_ message: RtmMessage) {
        
    }
    
    func resolveSync() {
        
    }
    
    func appToAppVerificationResponse(success: Bool, reason: A2AVerificationError?) {
        
    }
    
    func logoutResponseMessage() -> RtmMessageResponse? {
        return nil
    }
    
    func statusResponseMessage(message: String, type: WvConfig.WVMessageType) -> RtmMessageResponse? {
        return nil
    }
    
    func versionResponseMessage(version: WvConfig.RtmProtocolVersion) -> RtmMessageResponse? {
        return nil
    }
    
}
