import Foundation

class RtmMessageHandlerV2: NSObject, RtmMessageHandler {
    
    enum RtmMessageTypeVer2: String, RtmMessageTypeWithHandler {
        case rtmVersion = "version"
        case sync
        case deviceStatus
        case userData
        case logout
        case resolve
        
        func msgHandlerFor(handlerObject: RtmMessageHandler) -> MessageTypeHandler? {
            switch self {
            case .userData:
                return handlerObject.handleSessionData
            case .sync:
                return handlerObject.handleSync
            case .deviceStatus, .logout, .resolve, .rtmVersion:
                return nil
            }
        }
    }
    
    weak var outputDelegate: RtmOutputDelegate?
    weak var wvRtmDelegate: RTMDelegate?
    
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate?
    weak var cardScannerDataSource: FitpayCardScannerDataSource?
    weak var a2aVerificationDelegate: FitpayA2AVerificationDelegate?
    
    var wvConfigStorage: WvConfigStorage!
    var webViewSessionData: SessionData?
    var restClient: RestClient?

    var syncCallBacks = [RtmMessage]()
    
    required init(wvConfigStorage: WvConfigStorage) {
        self.wvConfigStorage = wvConfigStorage
    }
    
    func handle(message: [String: Any]) {
        let jsonData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
        
        guard let rtmMessage = try? RtmMessage(String(data: jsonData!, encoding: .utf8)) else {
            log.error("WV_DATA: Can't create RtmMessage.")
            return
        }
        
        if let handler = self.handlerFor(rtmMessage: rtmMessage.type ?? "") {
            handler(rtmMessage)
        }
    }
    
    func handlerFor(rtmMessage: String) -> MessageTypeHandler? {
        guard let messageAction = RtmMessageTypeVer2(rawValue: rtmMessage) else {
            log.error("WV_DATA: RtmMessage. Action is missing or unknown: \(rtmMessage)")
            return nil
        }
        
        return messageAction.msgHandlerFor(handlerObject: self)
    }
    
    func handleSync(_ message: RtmMessage) {
        log.verbose("WV_DATA: Handling rtm sync.")
        
        guard let _ = self.webViewSessionData,
            let user = self.wvConfigStorage.user,
            let deviceInfo = self.wvConfigStorage.device,
            let paymentDevice = self.wvConfigStorage.paymentDevice else {
                log.warning("WV_DATA: rtm not yet configured to handle syncs requests, failing sync.")
                if let delegate = self.outputDelegate {
                    delegate.send(rtmMessage: RtmMessageResponse(callbackId: self.syncCallBacks.first?.callBackId ?? 0,
                                                                 data: WvConfig.WVResponse.noSessionData.dictionaryRepresentation(),
                                                                 type: RtmMessageTypeVer2.sync.rawValue,
                                                                 success: false), retries: 3)
                    delegate.show(status: .syncError, message: "Can't make sync. Session data or user or deviceInfo or payment device is nil.", error: nil)
                }
                return
        }
        
        log.verbose("WV_DATA: Adding sync to rtm callback queue.")
        syncCallBacks.append(message)
        log.verbose("WV_DATA: initiating sync.")
        SyncRequestQueue.sharedInstance.add(request: SyncRequest(user: user, deviceInfo: deviceInfo, paymentDevice: paymentDevice, initiator: .platform), completion: nil)
    }
    
    func handleSessionData(_ message: RtmMessage) {
        guard let webViewSessionData = try? SessionData(message.data) else {
            log.error("WV_DATA: Can't parse SessionData from rtmBridge message. Message: \(String(describing: message.data))")
            return
        }

        self.webViewSessionData = webViewSessionData
        self.restClient = RestSession.GetUserAndDeviceWith(sessionData: webViewSessionData) { [weak self] (user, device, error) in
            guard error == nil else {
                if let delegate = self?.outputDelegate {
                    delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId,
                                                                 data: WvConfig.WVResponse.failed.dictionaryRepresentation(param: error.debugDescription),
                                                                 type: RtmMessageTypeVer2.userData.rawValue,
                                                                 success: false), retries: 3)
                    delegate.show(status: .syncError, message: "Can't get user, error: \(error.debugDescription)", error: error)
                }

                FitpayEventsSubscriber.sharedInstance.executeCallbacksForEvent(event: .getUserAndDevice, status: .failed, reason: error)
                return
            }
                                                            
            self?.wvConfigStorage.user = user
            self?.wvConfigStorage.device = device
            self?.wvConfigStorage.paymentDevice?.deviceInfo?.client = self?.wvConfigStorage.user?.client

            if let delegate = self?.wvRtmDelegate, let email = user?.email {
                delegate.didAuthorizeWith(email: email)
            }

            if self?.wvConfigStorage.rtmConfig?.hasAccount == false {
                FitpayEventsSubscriber.sharedInstance.executeCallbacksForEvent(event: .userCreated)
            }

            FitpayEventsSubscriber.sharedInstance.executeCallbacksForEvent(event: .getUserAndDevice)

            if let delegate = self?.outputDelegate {
                delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId,
                                                             data: WvConfig.WVResponse.success.dictionaryRepresentation(),
                                                             type: RtmMessageTypeVer2.resolve.rawValue,
                                                             success: true), retries: 3)
            }
        }
        FitpayNotificationsManager.sharedInstance.setRestClient(self.restClient)
    }

    func logoutResponseMessage() -> RtmMessageResponse? {
        return RtmMessageResponse(type: RtmMessageTypeVer2.logout.rawValue)
    }

    func versionResponseMessage(version: WvConfig.RtmProtocolVersion) -> RtmMessageResponse? {
        return RtmMessageResponse(data: ["version": version.rawValue], type: RtmMessageTypeVer2.rtmVersion.rawValue)
    }
    
    func statusResponseMessage(message: String, type: WvConfig.WVMessageType) -> RtmMessageResponse? {
        return RtmMessageResponse(data: ["message": message, "type": type.rawValue], type: RtmMessageTypeVer2.deviceStatus.rawValue)
    }

    func resolveSync() {
        if let message = self.syncCallBacks.first {
            log.verbose("WV_DATA: resolving rtm sync promise.")
            if let delegate = self.outputDelegate {
                if self.syncCallBacks.count > 1 {
                    delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId, data: WvConfig.WVResponse.successStillWorking.dictionaryRepresentation(param: self.syncCallBacks.count), type: RtmMessageTypeVer2.sync.rawValue, success: true), retries: 3)
                    log.verbose("WV_DATA: there was another rtm sync request, syncing again.")
                } else {
                    delegate.send(rtmMessage: RtmMessageResponse(callbackId: message.callBackId, data: WvConfig.WVResponse.success.dictionaryRepresentation(), type: RtmMessageTypeVer2.sync.rawValue, success: true), retries: 3)
                    
                    log.verbose("WV_DATA. no more rtm sync requests in queue.")
                }
            }

            self.syncCallBacks.removeFirst()
        }
    }

}
