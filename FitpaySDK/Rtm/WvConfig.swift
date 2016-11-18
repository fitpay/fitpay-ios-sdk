
import Foundation
import WebKit
import ObjectMapper

public enum WVMessageType : Int {
    case error = 0
    case success
    case progress
    case pending
}

@objc public enum WVDeviceStatuses : Int {
    case disconnected = 0
    case pairing
    case connected
    case synchronizing
    case syncStarted
    case syncDataRetrieved
    case synchronized
    case syncError
    
    func statusMessageType() -> WVMessageType {
        switch self {
        case .disconnected:
            return .pending
        case .connected,
             .synchronized:
            return .success
        case .pairing,
             .synchronizing,
             .syncStarted,
             .syncDataRetrieved:
            return .progress
        case .syncError:
            return .error
        }
    }
    
    func defaultMessage() -> String {
        switch self {
        case .disconnected:
            return "Device is disconnected."
        case .connected:
            return "Ready to sync with device."
        case .synchronized:
            return "Device is up to date."
        case .pairing:
            return "Pairing with device..."
        case .synchronizing:
            return "Synchronizing with device."
        case .syncStarted:
            return "Synchronizing with device.."
        case .syncDataRetrieved:
            return "Synchronizing with device..."
        case .syncError:
            return "Sync error"
        }
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


open class WvConfig : NSObject, WKScriptMessageHandler {

    @available(*, unavailable, message: "use rtmDelegate: instead")
    weak open var delegate : WvConfigDelegate?
    
    weak open var rtmDelegate : WvRTMDelegate?

    var url = BASE_URL
    let paymentDevice: PaymentDevice?
    open let restSession: RestSession?
    open let restClient: RestClient?
    let notificationCenter = NotificationCenter.default

    open var user: User?
    var rtmConfig: RtmConfig?
    var webViewSessionData: WebViewSessionData?
    var webview: WKWebView?
    var connectionBinding: FitpayEventBinding?
    var sessionDataCallBack: RtmMessage?
    var syncCallBacks = [RtmMessage]()
    
    open var demoModeEnabled : Bool {
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
    
    public convenience init(clientId:String, redirectUri:String, paymentDevice:PaymentDevice, userEmail:String?, isNewAccount:Bool) {
        self.init(paymentDevice: paymentDevice, rtmConfig: RtmConfig(clientId: clientId, redirectUri: redirectUri, userEmail: userEmail, deviceInfo: nil, hasAccount: !isNewAccount), SDKConfiguration: FitpaySDKConfiguration(clientId: clientId, redirectUri: redirectUri, baseAuthURL: AUTHORIZE_BASE_URL, baseAPIURL: API_BASE_URL))
    }
    
    public init(paymentDevice:PaymentDevice, rtmConfig: RtmConfig, SDKConfiguration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration) {
        self.paymentDevice = paymentDevice
        self.rtmConfig = rtmConfig
        self.restSession = RestSession(configuration: SDKConfiguration)
        self.restClient = RestClient(session: self.restSession!)
        self.paymentDevice!.deviceInfo?.client = self.restClient
        
        self.url = SDKConfiguration.webViewURL
        
        SyncManager.sharedInstance.paymentDevice = paymentDevice
        
        super.init()
        
        self.demoModeEnabled = false

        self.notificationCenter.addObserver(self, selector: #selector(logout), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        self.bindEvents()
    }

    /**
      In order to open a web-view the SDK must have a connection to the payment device in order to gather data about 
      that device. This will attempt to connect, and call the completion with either an error or nil if the connection 
      attempt is successful.
     */
    open func openDeviceConnection(_ completion: @escaping (_ error:NSError?) -> Void) {
        self.connectionBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected, completion: {
            (event) in
            
            self.paymentDevice!.removeBinding(binding: self.connectionBinding!)

            if let error = (event.eventData as! [String: Any])["error"] as? NSError {
                completion(error)
                return
            }

            if let deviceInfo = (event.eventData as! [String: Any])["deviceInfo"] as? DeviceInfo {
                self.rtmConfig?.deviceInfo = deviceInfo
                completion(nil)
                return
            }

            completion(NSError.error(code: 1, domain: WvConfig.self, message: "Could not open connection. OnDeviceConnected event did not supply valid device data"))
        })
        
        self.paymentDevice!.connect()
    }
    
    open func setWebView(_ webview:WKWebView!) {
        self.webview = webview
    }
    
    /**
     This returns the configuration for a WKWebView that will enable the iOS rtm bridge in the web app. Note that
     the value "rtmBridge" is an agreeded upon value between this and the web-view.
     */
    open func wvConfig() -> WKWebViewConfiguration {
        let config:WKWebViewConfiguration = WKWebViewConfiguration()
        config.userContentController.add(self, name: "rtmBridge")
        
        return config
    }
    
    /**
     This returns the request object clients will require in order to open a WKWebView
     */
    open func wvRequest() -> URLRequest {
        let JSONString = Mapper().toJSONString(rtmConfig!)
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
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let sentData = message.body as? [String : Any] else {
            log.error("Received message from \(message.name), but can't convert it to dictionary type.")
            return
        }
        
		let jsonData = try? JSONSerialization.data(withJSONObject: sentData, options: .prettyPrinted)
        
        guard let rtmMessage = Mapper<RtmMessage>().map(JSONString: String(data: jsonData!, encoding: .utf8)!) else {
            log.error("Can't create RtmMessage.")
            return
        }
        
        guard let messageAction = rtmMessage.type else {
            log.error("RtmMessage. Action is missing")
            return
        }
        
        switch messageAction {
            case "sync":
                log.verbose("received sync message from web-view")
                handleSync(rtmMessage)
                break
            case "userData":
                log.verbose("received user session data from web-view")
                
                sessionDataCallBack = rtmMessage
                
                guard let data = rtmMessage.data as? NSDictionary else {
                    log.error("Can't get data from rtmBridge message.")
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String

                    guard let webViewSessionData = Mapper<WebViewSessionData>().map(JSONString: jsonString) else {
                        log.error("Can't parse WebViewSessionData from rtmBridge message. Message: \(jsonString)")
                        return
                    }
                    
                    handleSessionData(webViewSessionData)
                } catch let error as NSError {
                    log.error(error)
                }
                break
            default:
                break
        }
        
        rtmDelegate?.onWvMessageReceived?(message: rtmMessage)
    }
    
    open func showStatusMessage(_ status: WVDeviceStatuses, message: String? = nil, error: Error? = nil) {
        var realMessage = message ?? status.defaultMessage()
        if let newMessage = rtmDelegate?.willDisplayStatusMessage?(status, defaultMessage: realMessage, error: error as? NSError) {
            realMessage = newMessage
        }
        
        sendStatusMessage(realMessage, type: status.statusMessageType())
    }
    
    open func showCustomStatusMessage(_ message:String, type: WVMessageType) {
        sendStatusMessage(message, type: type)
    }
    
    open func sendRtmMessage(rtmMessage: RtmMessageResponse) {
        guard let jsonRepresentation = rtmMessage.toJSONString(prettyPrint: false) else {
            log.error("Can't create json representation for rtm message.")
            return
        }

        webview?.evaluateJavaScript("window.RtmBridge.resolve(\(jsonRepresentation))", completionHandler: { (result, error) in
            if let error = error {
                log.error("Can't send status message, error: \(error)")
            }
        })
    }
    
    fileprivate func sendStatusMessage(_ message:String, type:WVMessageType) {
        sendRtmMessage(rtmMessage: RtmMessageResponse(data:["message":message, "type":type.rawValue], type: "deviceStatus"))
    }
    
    fileprivate func handleSync(_ message: RtmMessage) -> Void {
        log.verbose("--- [WvConfig] handling rtm sync ---")
        if (self.webViewSessionData != nil && self.user != nil ) {
            log.verbose("--- [WvConfig] adding sync to rtm callback queue ---")
            syncCallBacks.append(message)
            if !SyncManager.sharedInstance.isSyncing {
                self.showStatusMessage(.syncStarted)
                log.verbose("--- [WvConfig] initiating sync ---")
                goSync()
            } else {
                log.verbose("--- [WvConfig] sync manager was syncing in RTM sync request. So doing nothing ---")
            }
        } else {
            log.verbose("--- [WvConfig] rtm not yet configured to hand syncs requests, failing sync ---")
            sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: self.syncCallBacks.first!.callBackId, data: WVResponse.noSessionData.dictionaryRepresentation(), type: "sync", success: false))
            self.showStatusMessage(.syncError, message: "Can't make sync. Session data or user is nil.")
        }
    }
    
    fileprivate func handleSessionData(_ webViewSessionData:WebViewSessionData) -> Void {
        self.webViewSessionData = webViewSessionData
        self.restSession!.setWebViewAuthorization(webViewSessionData)

        restClient?.user(id: (self.webViewSessionData?.userId)!, completion: {
            (user, error) in
            
            guard (error == nil || user == nil) else {
                
                self.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: self.sessionDataCallBack?.callBackId, data: WVResponse.failed.dictionaryRepresentation(param: error.debugDescription), type: "userData", success: false))

                self.showStatusMessage(.syncError, message: "Can't get user, error: \(error.debugDescription)", error: error)
                
                return
            }

            self.user = user

            if let delegate = self.rtmDelegate {
                delegate.didAuthorizeWithEmail(user?.email)
            }
            
            self.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: self.sessionDataCallBack?.callBackId, data: WVResponse.success.dictionaryRepresentation(), type: "resolve", success: true))

            self.showStatusMessage(.synchronizing)
        })
    }

    fileprivate func rejectAndResetSyncCallbacks(_ reason:String) {
        log.verbose("--- [WvConfig] rejecting and resettting callback queue in rtm ---")
        for cb in self.syncCallBacks {
            self.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: cb.callBackId, data: WVResponse.failed.dictionaryRepresentation(param: reason), type: "sync", success: false))
        }

        self.syncCallBacks = [RtmMessage]()
    }

    fileprivate func resolveSync() {
        if let message = self.syncCallBacks.first {
            log.verbose("--- [WvConfig] resolving rtm sync promise ---")
            if self.syncCallBacks.count > 1 {
                sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: message.callBackId, data: WVResponse.successStillWorking.dictionaryRepresentation(param: self.syncCallBacks.count), type: "sync", success: true))
                log.verbose("--- [WvConfig] there was another rtm sync request, syncing again ---")
                goSync()
            } else {
                self.sendRtmMessage(rtmMessage: RtmMessageResponse(callbackId: message.callBackId, data: WVResponse.success.dictionaryRepresentation(), type: "sync", success: true))

                self.showStatusMessage(.synchronized)
                log.verbose("--- [WvConfig] no more rtm sync requests in queue ---")
            }

            self.syncCallBacks.removeFirst()
        } else {
            log.warning("no callbacks available for sync resolution")
        }
    }

    fileprivate func goSync() {
        log.verbose("--- [WvConfig] initiating SyncManager sync via rtm ---")
        if SyncManager.sharedInstance.sync(self.user!) != nil {
            rejectAndResetSyncCallbacks("SyncManager failed to regulate sequential syncs, all pending syncs have been rejected")
        }
    }

    fileprivate func bindEvents() {
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted, completion: {
            (event) in
            log.debug("--- [WvConfig] received sync complete from SyncManager ---")

            self.resolveSync()
        })

        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed, completion: {
            (event) in
            log.error("--- [WvConfig] reveiced sync FAILED from SyncManager ---")
            self.showStatusMessage(.syncError, error: (event.eventData as? [String:Any])?["error"] as? Error)

            self.rejectAndResetSyncCallbacks("SyncManager failed to complete the sync, all pending syncs have been rejected")
        })
    }

    @objc fileprivate func logout() {
        if let _ = user {
            sendRtmMessage(rtmMessage: RtmMessageResponse(type: "logout"))
        }
    }

}

