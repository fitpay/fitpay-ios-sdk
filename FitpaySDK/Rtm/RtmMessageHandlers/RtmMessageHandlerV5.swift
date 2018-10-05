import Foundation

class RtmMessageHandlerV5: RtmMessageHandlerV4 {
    
    enum RtmMessageTypeVer5: String, RtmMessageTypeWithHandler {
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
        case idVerificationRequest
        case idVerification
        case supportsIssuerAppVerification
        case appToAppVerification
        case navigationStart
        case navigationSuccess
        case apiErrorDetails
        
        func msgHandlerFor(handlerObject: RtmMessageHandler) -> MessageTypeHandler? {
            guard let handlerObject = handlerObject as? RtmMessageHandlerV5 else { return nil }
            
            switch self {
            case .userData:
                return handlerObject.handleSessionData
            case .sync:
                return handlerObject.handleSync
            case .scanRequest:
                return handlerObject.handleScanRequest
            case .sdkVersionRequest:
                return handlerObject.handleSdkVersion
            case .idVerificationRequest:
                return handlerObject.handleIdVerificationRequest
            case .supportsIssuerAppVerification:
                return handlerObject.issuerAppVerificationRequest
            case .appToAppVerification:
                return handlerObject.handleAppToAppVerificationRequest
            case .apiErrorDetails:
                return handlerObject.handleApiErrorDetails
            case .deviceStatus,
                 .logout,
                 .resolve,
                 .rtmVersion,
                 .cardScanned,
                 .sdkVersion,
                 .idVerification,
                 .navigationStart,
                 .navigationSuccess:
                return nil
            }
        }
    }
    
    private var appToAppMessage: RtmMessage?

    // MARK: - Functions
    
    override func handlerFor(rtmMessage: String) -> MessageTypeHandler? {
        guard let messageAction = RtmMessageTypeVer5(rawValue: rtmMessage) else {
            log.debug("WV_DATA: RtmMessage. Action is missing or unknown: \(rtmMessage)")
            return nil
        }
        
        return messageAction.msgHandlerFor(handlerObject: self)
    }
    
    override func appToAppVerificationResponse(success: Bool, reason: A2AVerificationError?) {
        guard let delegate = self.outputDelegate else { return }
        guard let appToAppMessage = appToAppMessage else { return }
        
        if success {
            delegate.send(rtmMessage: RtmMessageResponse(callbackId: appToAppMessage.callBackId,
                                                         data: appToAppMessage.data,
                                                         type: RtmMessageTypeVer5.appToAppVerification.rawValue,
                                                         success: true), retries: 3)
        } else if let reason = reason {
            let data = ["reason": reason.rawValue]
            delegate.send(rtmMessage: RtmMessageResponse(callbackId: appToAppMessage.callBackId,
                                                         data: data,
                                                         type: RtmMessageTypeVer5.appToAppVerification.rawValue,
                                                         success: false), retries: 3)
            
        }
        
        self.appToAppMessage = nil
    }
    
    // MARK: - Private
    
    private func handleIdVerificationRequest(_ message: RtmMessage) {
        wvConfigStorage.paymentDevice?.handleIdVerificationRequest { [weak self] (response) in
            if let delegate = self?.outputDelegate {
                delegate.send(rtmMessage: RtmMessageResponse(data: response.toJSON(), type: RtmMessageTypeVer5.idVerification.rawValue, success: true), retries: 3)
            }
        }
    }
    
    private func issuerAppVerificationRequest(_ message: RtmMessage) {
        guard let delegate = self.outputDelegate else { return }
        let data = [RtmMessageTypeVer5.supportsIssuerAppVerification.rawValue: FitpayConfig.supportApp2App]
        delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId,
                                                     data: data,
                                                     type: RtmMessageTypeVer5.supportsIssuerAppVerification.rawValue,
                                                     success: true), retries: 3)
    }
    
    private func handleAppToAppVerificationRequest(_ message: RtmMessage) {
        appToAppMessage = message
        
        guard let appToAppVerification = try? A2AVerificationRequest(message.data) else {
            appToAppVerificationResponse(success: false, reason: .cantProcess)
            return
        }
        
        guard FitpayConfig.supportApp2App && appToAppVerification.cardType != "MASTERCARD" else {
            appToAppVerificationResponse(success: false, reason: .notSupported)
            return
        }
        
        wvConfigStorage.a2aReturnLocation = appToAppVerification.returnLocation
        a2aVerificationDelegate?.verificationFinished(verificationInfo: appToAppVerification)
    }

    private func handleApiErrorDetails(_ message: RtmMessage) {
        let code = message.data?["code"] as? Int
        var developerMessage: Any = "unknown error"
        
        if let detailedMessage = message.data?["detailedMessage"] {
            developerMessage = detailedMessage
        } else if let fullMessage = message.data?["fullMessage"] {
            developerMessage = fullMessage
        }
        
        log.error("WV_DATA: API Error - Code: \(code ?? 0) Message: \(developerMessage)")
    }
    
}
