import Foundation

class RtmMessageHandlerV4: RtmMessageHandlerV2 {
    var cardScanner: IFitpayCardScanner?
    
    enum RtmMessageTypeVer4: String, RtmMessageTypeWithHandler {
        case rtmVersion = "version"
        case sync
        case deviceStatus
        case userData
        case logout
        case resolve
        case scanRequest
        case cardScanned
        case sdkVersionRequest
        case sdkVersion
        
        func msgHandlerFor(handlerObject: RtmMessageHandler) -> MessageTypeHandler? {
            guard let handlerObject = handlerObject as? RtmMessageHandlerV4 else {
                return nil
            }
            
            switch self {
            case .userData:
                return handlerObject.handleSessionData
            case .sync:
                return handlerObject.handleSync
            case .scanRequest:
                return handlerObject.handleScanRequest
            case .sdkVersionRequest:
                return handlerObject.handleSdkVersion
            case .deviceStatus,
                 .logout,
                 .resolve,
                 .rtmVersion,
                 .cardScanned,
                 .sdkVersion:
                return nil
            }
        }
    }
    
    override func handlerFor(rtmMessage: String) -> MessageTypeHandler? {
        guard let messageAction = RtmMessageTypeVer4(rawValue: rtmMessage) else {
            log.debug("WV_DATA: RtmMessage. Action is missing or unknown: \(rtmMessage)")
            return nil
        }
        
        return messageAction.msgHandlerFor(handlerObject: self)
    }
    
    func handleScanRequest(_ message: RtmMessage) {
        if let cardScannerDataSource = self.cardScannerDataSource {
            self.cardScanner = cardScannerDataSource.cardScanner()
            self.cardScanner?.scanDelegate = self
            if let cardScannerPresenter = self.cardScannerPresenterDelegate {
                cardScannerPresenter.shouldPresentCardScanner(scanner: self.cardScanner!)
            }
        }
    }
    
    // MARK: - Private
    
    private func handleSdkVersion(_ message: RtmMessage) {
        let result = [RtmMessageTypeVer4.sdkVersion.rawValue: "iOS-\(FitpayConfig.sdkVersion)"]
        if let delegate = self.outputDelegate {
            delegate.send(rtmMessage: RtmMessageResponse(data: result, type: RtmMessageTypeVer4.sdkVersion.rawValue, success: true), retries: 3)
        }
    }
    
}

extension RtmMessageHandlerV4: FitpayCardScannerDelegate {
    
    func scanned(card: ScannedCardInfo?, error: Error?) {
        if let delegate = self.outputDelegate {
            delegate.send(rtmMessage: RtmMessageResponse(data: card?.toJSON(), type: RtmMessageTypeVer4.cardScanned.rawValue, success: true), retries: 3)
        }
        
        if let cardScannerPresenter = self.cardScannerPresenterDelegate, let cardScanner = self.cardScanner {
            cardScannerPresenter.shouldDissmissCardScanner(scanner: cardScanner)
        }
    }
    
    func canceled() {
        if let cardScannerPresenter = self.cardScannerPresenterDelegate, let cardScanner = self.cardScanner {
            cardScannerPresenter.shouldDissmissCardScanner(scanner: cardScanner)
        }
    }

}
