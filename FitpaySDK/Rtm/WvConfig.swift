
import Foundation
import WebKit
import ObjectMapper

@objc public enum WVMessageType : Int {
    case error = 0
    case success
    case progress
    case pending
}

@objc public enum WVDeviceStatuses : Int {
    case disconnected
    case pairing
    case syncGettingUpdates
    case syncNoUpdates
    case syncUpdatingConnectingToDevice
    case syncUpdatingConnectionFailed
    case syncUpdating
    case syncComplete
    case syncError
    
    func statusMessageType() -> WVMessageType {
        switch self {
        case .disconnected:
            return .pending
        case .syncGettingUpdates,
             .syncNoUpdates,
             .syncUpdatingConnectingToDevice,
             .syncUpdating,
             .syncComplete:
            return .success
        case .pairing,
             .syncUpdatingConnectionFailed:
            return .progress
        case .syncError:
            return .error
        }
    }
    
    func defaultMessage() -> String {
        switch self {
        case .disconnected:
            return "Device is disconnected."
        case .syncGettingUpdates:
            return "Checking for wallet updates ..."
        case .syncNoUpdates:
            return "No pending updates for device"
        case .pairing:
            return "Pairing with device..."
        case .syncUpdatingConnectingToDevice:
            return "Updates available for wallet - connecting to device ..."
        case .syncUpdatingConnectionFailed:
            return "Updates available for wallet - unable to connect to device - check connection"
        case .syncUpdating:
            return "Syncing updates to device ..."
        case .syncComplete:
            return "Sync complete - device up to date - no updates available"
        case .syncError:
            return "Sync error"
        }
    }
}

@objc public enum RtmProtocolVersion: Int {
    case ver1 = 1
    case ver2
    
    static func currentlySupportedVersion() -> RtmProtocolVersion {
        return .ver2
    }
}

@available(*, deprecated, message: "use WvRTMDelegate: instead")
@objc public protocol WvConfigDelegate : NSObjectProtocol {
    /**
     This method will be called after successful user authorization.
     */
    func didAuthorizeWithEmail(_ email:String?)
    
    /**
     This method can be used for user messages customization.
     
     Will be called when status has changed and system going to show message.
     
     - parameter status:         New device status
     - parameter defaultMessage: Default message for new status
     - parameter error:          If we had an error during status change than it will be here.
                                 For now error will be used with SyncError status
     
     - returns:                  Message string which will be shown on status board.
     */
    @objc optional func willDisplayStatusMessage(_ status:WVDeviceStatuses, defaultMessage:String, error: NSError?) -> String
}

@objc public protocol WvRTMDelegate : NSObjectProtocol {
    /**
     This method will be called after successful user authorization.
     */
    func didAuthorizeWithEmail(_ email:String?)
    
    /**
     This method can be used for user messages customization.
     
     Will be called when status has changed and system going to show message.
     
     - parameter status:         New device status
     - parameter defaultMessage: Default message for new status
     - parameter error:          If we had an error during status change than it will be here.
     For now error will be used with SyncError status
     
     - returns:                  Message string which will be shown on status board.
     */
    @objc optional func willDisplayStatusMessage(_ status:WVDeviceStatuses, defaultMessage:String, error: NSError?) -> String
    
    /**
     Called when the message from wv was delivered to SDK.
     
     - parameter message: message from web view
     */
    @objc optional func onWvMessageReceived(message: RtmMessage)
}


/**
 These responses must conform to what is expected by the web-view. Changing their structure also requires
 changing them in the rtmIosImpl.js
 */
internal enum WVResponse: Int {
    
    case success = 0
    case failed
    case successStillWorking
    case noSessionData
    
    func dictionaryRepresentation(param: Any? = nil) -> [String:Any]{
        switch self {
        case .success, .noSessionData:
        	return ["status":rawValue]
        case .failed:
            return ["status":rawValue, "reason":param ?? "unknown"]
        case .successStillWorking:
            return ["status":rawValue, "count":param ?? "unknown"]
        }
    }
}


@objc open class WvConfig : NSObject, WKScriptMessageHandler {
    public enum ErrorCode : Int, Error, RawIntValue, CustomStringConvertible
    {
        case unknownError                   = 0
        case deviceNotFound                 = 10001
        case deviceDataNotValid				= 10002
        
        public var description : String {
            switch self {
            case .unknownError:
                return "Unknown error"
            case .deviceNotFound:
                return "Can't find device provided by wv."
            case .deviceDataNotValid:
                return "Could not open connection. OnDeviceConnected event did not supply valid device data."
            }
        }
    }

    @available(*, unavailable, message: "use rtmDelegate: instead")
    weak open var delegate : WvConfigDelegate?
    
    weak open var rtmDelegate : WvRTMDelegate?

    var url = BASE_URL
    let paymentDevice: PaymentDevice?
    open let restSession: RestSession?
    open let restClient: RestClient?
    let notificationCenter = NotificationCenter.default

    typealias MessagesHandlerBlock = (_ message: [String:Any]) -> ()
    var messagesHandler: MessagesHandlerBlock!
    
    public var user: User?
    public var device: DeviceInfo?
    
    var rtmConfig: RtmConfig?
    var webViewSessionData: WebViewSessionData?
    var webview: WKWebView?
    var connectionBinding: FitpayEventBinding?
    var sessionDataCallBack: RtmMessage?
    var syncCallBacks = [RtmMessage]()
    
    fileprivate var rtmVersionSent = false
    
    @objc open var demoModeEnabled : Bool {
        get {
            if let isEnabled = self.rtmConfig?.demoMode {
                return isEnabled
            }
            return false
        }
        set {
            self.rtmConfig?.demoMode = newValue
        }
    }
    
    @objc public convenience init(clientId:String, redirectUri:String, paymentDevice:PaymentDevice, userEmail:String?, isNewAccount:Bool) {
        self.init(paymentDevice: paymentDevice, rtmConfig: RtmConfig(clientId: clientId, redirectUri: redirectUri, userEmail: userEmail, deviceInfo: nil, hasAccount: !isNewAccount), SDKConfiguration: FitpaySDKConfiguration(clientId: clientId, redirectUri: redirectUri, baseAuthURL: AUTHORIZE_BASE_URL, baseAPIURL: API_BASE_URL))
    }
    
    @objc public init(paymentDevice:PaymentDevice, rtmConfig: RtmConfig, SDKConfiguration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration) {
        self.paymentDevice = paymentDevice
        self.rtmConfig = rtmConfig
        self.restSession = RestSession(configuration: SDKConfiguration)
        self.restClient = RestClient(session: self.restSession!)
        self.paymentDevice!.deviceInfo?.client = self.restClient
        
        self.url = SDKConfiguration.webViewURL
        
        
        SyncManager.sharedInstance.paymentDevice = paymentDevice
        
        super.init()
        
        self.messagesHandler = { [weak self] (message) in
            self?.defaultMessagesHandler(message)
        }

        self.demoModeEnabled = false

        self.notificationCenter.addObserver(self, selector: #selector(logout), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        self.bindEvents()
    }

    deinit {
        self.notificationCenter.removeObserver(self)
        self.webview?.configuration.userContentController.removeScriptMessageHandler(forName: "rtmBridge")
    }
    
    /**
      In order to open a web-view the SDK must have a connection to the payment device in order to gather data about 
      that device. This will attempt to connect, and call the completion with either an error or nil if the connection 
      attempt is successful.
     */
    @objc open func openDeviceConnection(_ completion: @escaping (_ error:NSError?) -> Void) {
        self.connectionBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected, completion: {
            [weak self] (event) in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.paymentDevice!.removeBinding(binding: strongSelf.connectionBinding!)

            if let error = (event.eventData as! [String: Any])["error"] as? NSError {
                completion(error)
                return
            }

            if let deviceInfo = (event.eventData as! [String: Any])["deviceInfo"] as? DeviceInfo {
                strongSelf.rtmConfig?.deviceInfo = deviceInfo
                completion(nil)
                return
            }

            
            completion(NSError.error(code:WvConfig.ErrorCode.deviceDataNotValid, domain: WvConfig.self))
        })
        
        self.paymentDevice!.connect()
    }
    
    @objc open func setWebView(_ webview:WKWebView!) {
        self.webview = webview
    }
    
    @objc open func webViewPageLoaded() {
        if !rtmVersionSent {
            sendVersion(version: RtmProtocolVersion.currentlySupportedVersion())
        }
    }
    
    /**
     This returns the configuration for a WKWebView that will enable the iOS rtm bridge in the web app. Note that
     the value "rtmBridge" is an agreeded upon value between this and the web-view.
     */
    @objc open func wvConfig() -> WKWebViewConfiguration {
        
        class LeakAvoider : NSObject, WKScriptMessageHandler {
            weak var delegate : WKScriptMessageHandler?
            init(delegate:WKScriptMessageHandler) {
                self.delegate = delegate
                super.init()
            }
            func userContentController(_ userContentController: WKUserContentController,
                                       didReceive message: WKScriptMessage) {
                self.delegate?.userContentController(
                    userContentController, didReceive: message)
            }
        }

        let config:WKWebViewConfiguration = WKWebViewConfiguration()
        config.userContentController.add(LeakAvoider(delegate: self), name: "rtmBridge")
        
        return config
    }
    
    /**
     This returns the request object clients will require in order to open a WKWebView
     */
    @objc open func wvRequest() -> URLRequest {
        if let accessToken = self.restSession!.accessToken {
            self.rtmConfig!.accessToken = accessToken
        }
        
        let JSONString = Mapper().toJSONString(self.rtmConfig!)
        let utfString = JSONString!.data(using: String.Encoding.utf8, allowLossyConversion: true)
        let encodedConfig = utfString?.base64URLencoded()
        let configuredUrl = "\(url)?config=\(encodedConfig! as String)"
        
        log.verbose(configuredUrl)
        
        let requestUrl = URL(string: configuredUrl)
        let request = URLRequest(url: requestUrl!)
        return request
    }
    
    /**
     This is the implementation of WKScriptMessageHandler, and handles any messages posted to the RTM bridge from 
     the web app. The callBackId corresponds to a JS callback that will resolve a promise stored in window.RtmBridge 
     that will be called with the result of the action once completed. It expects a message with the following format:

        {
            "callBackId": 1,
            "data": {
                "action": "action",
                "data": {
                    "userId": "userId",
                    "deviceId": "userId",
                    "token": "token"
                }
            }
        }
     */
    @objc open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let sentData = message.body as? [String : Any] else {
            log.error("WV_DATA: Received message from \(message.name), but can't convert it to dictionary type.")
            return
        }
        
        self.messagesHandler(sentData)
    }
    
    @objc open func showStatusMessage(_ status: WVDeviceStatuses, message: String? = nil, error: Error? = nil) {
        var realMessage = message ?? status.defaultMessage()
        if let newMessage = rtmDelegate?.willDisplayStatusMessage?(status, defaultMessage: realMessage, error: error as NSError?) {
            realMessage = newMessage
        }
        
        sendStatusMessage(realMessage, type: status.statusMessageType())
    }
    
    @objc open func showCustomStatusMessage(_ message:String, type: WVMessageType) {
        sendStatusMessage(message, type: type)
    }
    
    @objc open func sendRtmMessage(rtmMessage: RtmMessageResponse) {
        guard let jsonRepresentation = rtmMessage.toJSONString(prettyPrint: false) else {
            log.error("WV_DATA: Can't create json representation for rtm message.")
            return
        }

        log.debug("WV_DATA: sending data to wv: \(jsonRepresentation)")
        
        webview?.evaluateJavaScript("window.RtmBridge.resolve(\(jsonRepresentation))", completionHandler: { (result, error) in
            if let error = error {
                log.error("WV_DATA: Can't send status message, error: \(error)")
            }
        })
    }
    
    fileprivate func defaultMessagesHandler(_ message: [String:Any]) {
        let jsonData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted)
        
        guard let rtmMessage = Mapper<RtmMessage>().map(JSONString: String(data: jsonData!, encoding: .utf8)!) else {
            log.error("WV_DATA: Can't create RtmMessage.")
            return
        }
        
        guard let messageAction = RtmMessagesType(rawValue: rtmMessage.type ?? "") else {
            log.error("WV_DATA: RtmMessage. Action is missing or unknown: \(rtmMessage.type ?? "unk type")")
            return
        }
        
        switch messageAction {
        case .sync:
            log.debug("WV_DATA: received SYNC message from web-view: \(message).")
            handleSync(rtmMessage)
            break
        case .userData:
            log.verbose("WV_DATA: received user session data from web-view.")
            
            sessionDataCallBack = rtmMessage
            
            guard let data = rtmMessage.data as? NSDictionary else {
                log.error("WV_DATA: Can't get data from rtmBridge message.")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
                let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
                
                guard let webViewSessionData = Mapper<WebViewSessionData>().map(JSONString: jsonString) else {
                    log.error("WV_DATA: Can't parse WebViewSessionData from rtmBridge message. Message: \(jsonString)")
                    return
                }
                
                handleSessionData(webViewSessionData)
            } catch let error as NSError {
                log.error(error)
            }
            break
        case .rtmVersion:
            guard let versionDictionary = rtmMessage.data as? [String:Int], let versionInt = versionDictionary["version"] else {
                log.error("WV_DATA: Can't get version of rtm protocol. Data: \(String(describing: rtmMessage.data)).")
                return
            }
            
            guard let version = RtmProtocolVersion(rawValue: versionInt) else {
                log.error("WV_DATA: Unknown rtm version - \(versionInt).")
                return
            }
            
            log.debug("WV_DATA: received \(version) rtm version.")
            
            switch version {
            case .ver2:
                log.debug("WV_DATA: using default message handler.")
                self.messagesHandler = { [weak self] (message) in
                    self?.defaultMessagesHandler(message)
                }
                break
            case .ver1:
                log.error("WV_DATA: rtm version 1 not supported yet =(")
                break
            }
            break
        default:
            break
        }
        
        rtmDelegate?.onWvMessageReceived?(message: rtmMessage)
    }
    
    fileprivate func sendStatusMessage(_ message:String, type:WVMessageType) {
        sendRtmMessage(rtmMessage: RtmMessageResponse(data:["message":message, "type":type.rawValue], type: .deviceStatus))
        rtmVersionSent = true
    }
    
    fileprivate func handleSync(_ message: RtmMessage) -> Void {
        log.verbose("WV_DATA: Handling rtm sync.")
        if (self.webViewSessionData != nil && self.user != nil ) {
            log.verbose("WV_DATA: Adding sync to rtm callback queue.")
            syncCallBacks.append(message)
            if !SyncManager.sharedInstance.isSyncing {
                self.showStatusMessage(.syncGettingUpdates)
                log.verbose("WV_DATA: initiating sync.")
                goSync()
            } else {
                log.debug("WV_DATA: sync manager was syncing in RTM sync request. So doing nothing.")
            }
        } else {

            log.warning("WV_DATA: rtm not yet configured to hand syncs requests, failing sync.")
            sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: self.syncCallBacks.first!.callBackId, data: WVResponse.noSessionData.dictionaryRepresentation(), type: .sync, success: false))
            self.showStatusMessage(.syncError, message: "Can't make sync. Session data or user is nil.")
        }
    }
    
    fileprivate func handleSessionData(_ webViewSessionData:WebViewSessionData) -> Void {
        self.webViewSessionData = webViewSessionData
        self.restSession!.setWebViewAuthorization(webViewSessionData)

        let userAndDeviceReceived: (_ user: User?, _ device: DeviceInfo?, _ error: NSError?) -> Void =  {
            [weak self] (user, device, error) in
            guard error == nil else {
                self?.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: self?.sessionDataCallBack?.callBackId, data: WVResponse.failed.dictionaryRepresentation(param: error.debugDescription), type: .userData, success: false))
                
                self?.showStatusMessage(.syncError, message: "Can't get user, error: \(error.debugDescription)", error: error)
                FitpayEventsSubscriber.sharedInstance.executeCallbacksForEvent(event: .getUserAndDevice, status: .failed, reason: error)
                return
            }
            
            self?.user = user
            self?.device = device
            
            if let delegate = self?.rtmDelegate {
                delegate.didAuthorizeWithEmail(user?.email)
            }
            
            if self?.rtmConfig?.hasAccount == false {
                FitpayEventsSubscriber.sharedInstance.executeCallbacksForEvent(event: .userCreated)
            }
            
            FitpayEventsSubscriber.sharedInstance.executeCallbacksForEvent(event: .getUserAndDevice)
            
            self?.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: self?.sessionDataCallBack?.callBackId, data: WVResponse.success.dictionaryRepresentation(), type: .resolve, success: true))
            
        }
        
        restClient?.user(id: (self.webViewSessionData?.userId)!, completion: {
            [weak self] (user, error) in
            
            guard (error == nil || user == nil) else {
                userAndDeviceReceived(nil, nil, error)
                return
            }

            user?.listDevices(limit: 20, offset: 0, completion: { (devicesColletion, error) in
                guard (error == nil || devicesColletion == nil) else {
                    userAndDeviceReceived(nil, nil, error)
                    return
                }
                
                for device in devicesColletion!.results! {
                    if device.deviceIdentifier == self?.webViewSessionData!.deviceId {
                        userAndDeviceReceived(user!, device, nil)
                        return
                    }
                }
                
                devicesColletion?.collectAllAvailable({ (devices, error) in
                    guard (error == nil || devices == nil) else {
                        userAndDeviceReceived(nil, nil, error as NSError?)
                        return
                    }
                    
                    for device in devices! {
                        if device.deviceIdentifier == self?.webViewSessionData!.deviceId {
                            userAndDeviceReceived(user!, device, nil)
                            return
                        }
                    }
                    
                    userAndDeviceReceived(nil, nil, NSError.error(code:WvConfig.ErrorCode.deviceNotFound, domain: WvConfig.self))
                })
            })
        })
    }

    fileprivate func rejectAndResetSyncCallbacks(_ reason:String) {
        log.verbose("WV_DATA: rejecting and resettting callback queue in rtm.")
        for cb in self.syncCallBacks {
            self.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: cb.callBackId, data: WVResponse.failed.dictionaryRepresentation(param: reason), type: .sync, success: false))
        }

        self.syncCallBacks = [RtmMessage]()
    }

    fileprivate func resolveSync() {
        if let message = self.syncCallBacks.first {
            log.verbose("WV_DATA: resolving rtm sync promise.")
            if self.syncCallBacks.count > 1 {
                sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: message.callBackId, data: WVResponse.successStillWorking.dictionaryRepresentation(param: self.syncCallBacks.count), type: .sync, success: true))
                log.verbose("WV_DATA: there was another rtm sync request, syncing again.")
                goSync()
            } else {
                self.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: message.callBackId, data: WVResponse.success.dictionaryRepresentation(), type: .sync, success: true))

                log.verbose("WV_DATA. no more rtm sync requests in queue.")
            }

            self.syncCallBacks.removeFirst()
        } else {
            log.warning("WV_DATA: no callbacks available for sync resolution.")
        }
    }

    fileprivate func goSync() {
        log.verbose("WV_DATA: initiating SyncManager sync via rtm.")
        if SyncManager.sharedInstance.sync(self.user!, device: self.device) != nil {
            rejectAndResetSyncCallbacks("SyncManager failed to regulate sequential syncs, all pending syncs have been rejected")
        }
    }
    
    fileprivate func sendVersion(version: RtmProtocolVersion) {
        sendRtmMessage(rtmMessage: RtmMessageResponse(data: ["version":version.rawValue], type: .rtmVersion))
    }

    fileprivate func bindEvents() {
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted, completion: {
            [weak self] (event) in
            log.debug("WV_DATA: received sync complete from SyncManager.")

            self?.resolveSync()
            self?.showStatusMessage(.syncComplete)
        })

        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed, completion: {
            [weak self] (event) in
            log.error("WV_DATA: reveiced sync FAILED from SyncManager.")
            let error = (event.eventData as? [String:Any])?["error"] as? NSError
                
            if error?.code == SyncManager.ErrorCode.cantConnectToDevice.rawValue {
                self?.showStatusMessage(.syncUpdatingConnectionFailed)
            } else {
            	self?.showStatusMessage(.syncError, error: (event.eventData as? [String:Any])?["error"] as? Error)
            }

            self?.rejectAndResetSyncCallbacks("SyncManager failed to complete the sync, all pending syncs have been rejected")
        })
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .commitsReceived, completion: {
            [weak self] (event) in
            guard let commits = (event.eventData as! [String:[Commit]])["commits"] else {
                self?.showStatusMessage(.syncNoUpdates)
                return
            }
            if commits.count > 0 {
                self?.showStatusMessage(.syncUpdatingConnectingToDevice)
            } else {
                self?.showStatusMessage(.syncNoUpdates)
            }
        })
    }

    @objc fileprivate func logout() {
        if let _ = user {
            sendRtmMessage(rtmMessage: RtmMessageResponse(type: .logout))
        }
    }

}
