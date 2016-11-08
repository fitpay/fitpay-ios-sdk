
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
    @objc optional func onWvMessageReceived(message: [String:Any])
}


/**
 These responses must conform to what is expected by the web-view. Changing their structure also requires
 changing them in the rtmIosImpl.js
 */
internal enum WVResponse: String {
    case success              = "{status: 0}"
    case failed               = "{status: 1, reason: '%@'}"
    case successStillWorking  = "{status: 2, count:  '%@'}"
    case noSessionData        = "{status: 3}"
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
    var sessionDataCallBackId: Int?
    var syncCallBacks = [Int]()
    
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
        
        print(configuredUrl)
        
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
        guard let sentData = message.body as? NSDictionary else {
            print("Received message from \(message.name), but can't convert it to dictionary type.")
            return
        }
        
        if let sentDataSwiftDictionary = sentData as? [String:Any] {
            rtmDelegate?.onWvMessageReceived?(message: sentDataSwiftDictionary)
        }

        if (sentData["data"] as? NSDictionary)?["action"] as? String == "sync" {
            print("received sync message from web-view")
            if let callbackId = sentData["callBackId"] as? Int {
                handleSync(callbackId)
            } else {
                print("Can't get callbackId from rtmBridge message.")
            }
        } else if (sentData["data"] as? NSDictionary)?["action"] as? String == "userData" {
            print("received user session data from web-view")

            sessionDataCallBackId = sentData["callBackId"] as? Int

            guard let data = (sentData["data"] as? NSDictionary)?["data"] else {
                print("Can't get data from rtmBridge message.")
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
                let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
                guard let webViewSessionData = Mapper<WebViewSessionData>().map(JSONString: jsonString) else {
                    print("Can't parse WebViewSessionData from rtmBridge message. Message: \(jsonString)")
                    return
                }
                
                handleSessionData(webViewSessionData)
            } catch let error as NSError {
                print(error)
            }
        }
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
    
    fileprivate func sendStatusMessage(_ message:String, type:WVMessageType) {
        guard let webview = self.webview else {
            print("Can't send status message, webview is nil!")
            return
        }
        
        webview.evaluateJavaScript("window.RtmBridge.setDeviceStatus({\"message\":\"\(message)\",\"type\":\(type.rawValue)})", completionHandler: {
            (result, error) in
            
            if let error = error {
                print("Can't send status message, error: \(error)")
            }
        })
    }
    
    fileprivate func handleSync(_ callBackId:Int) -> Void {
        print("--- [WvConfig] handling rtm sync ---")
        if (self.webViewSessionData != nil && self.user != nil ) {
            print("--- [WvConfig] adding sync to rtm callback queue ---")
            syncCallBacks.append(callBackId)

            if !SyncManager.sharedInstance.isSyncing {
                self.showStatusMessage(.syncStarted)
                print("--- [WvConfig] initiating sync ---")
                goSync()
            } else {
                print("--- [WvConfig] sync manager was syncing in RTM sync request. So doing nothing ---")
            }
        } else {
            print("--- [WvConfig] rtm not yet configured to hand syncs requests, failing sync ---")
            self.callBack(
                self.syncCallBacks.first!,
                success: false,
                response: self.getWVResponse(WVResponse.noSessionData, message: nil))
            self.showStatusMessage(.syncError, message: "Can't make sync. Session data or user is nil.")
        }
    }
    
    fileprivate func handleSessionData(_ webViewSessionData:WebViewSessionData) -> Void {
        self.webViewSessionData = webViewSessionData
        self.restSession!.setWebViewAuthorization(webViewSessionData)

        restClient?.user(id: (self.webViewSessionData?.userId)!, completion: {
            (user, error) in
            
            guard (error == nil || user == nil) else {
                
                self.callBack(
                    self.sessionDataCallBackId!,
                    success: false,
                    response: self.getWVResponse(WVResponse.failed, message: error.debugDescription))

                self.showStatusMessage(.syncError, message: "Can't get user, error: \(error.debugDescription)", error: error)
                
                return
            }

            self.user = user

            if let delegate = self.rtmDelegate {
                delegate.didAuthorizeWithEmail(user?.email)
            }
            
            self.callBack(
                self.sessionDataCallBackId!,
                success: true,
                response: self.getWVResponse(WVResponse.success, message: nil))
            
            self.showStatusMessage(.synchronizing)
        })
    }

    fileprivate func rejectAndResetSyncCallbacks(_ reason:String) {
        print("--- [WvConfig] rejecting and resettting callback queue in rtm ---")
        for cbId in self.syncCallBacks {
            callBack(
                cbId,
                success: false,
                response: getWVResponse(WVResponse.failed, message: reason))
        }

        self.syncCallBacks = [Int]()
    }

    fileprivate func resolveSync() {
        if let id = self.syncCallBacks.first {
            print("--- [WvConfig] resolving rtm sync promise ---")
            if self.syncCallBacks.count > 1 {
                self.callBack(
                    id,
                    success: true,
                    response: getWVResponse(WVResponse.successStillWorking, message: "\(self.syncCallBacks.count)"))

                print("--- [WvConfig] there was another rtm sync request, syncing again ---")
                goSync()
            } else {
                self.callBack(
                    id,
                    success: true,
                    response: getWVResponse(WVResponse.success, message: nil))
                self.showStatusMessage(.synchronized)
                print("--- [WvConfig] no more rtm sync requests in queue ---")
            }

            self.syncCallBacks.removeFirst()
        } else {
            print("no callbacks available for sync resolution")
        }
    }

    fileprivate func callBack(_ callBackId:Int, success:Bool, response:String) {
        print("--- [WvConfig] calling web-view callback ---")
        self.webview!.evaluateJavaScript("window.RtmBridge.resolve(\(callBackId), \(success), \(response))", completionHandler: {
            (result, error) in

            if error != nil {
                print("--- [WvConfig] error evaluating JS from swift rtm bridge ---")
            }
        })
    }

    fileprivate func goSync() {
        print("--- [WvConfig] initiating SyncManager sync via rtm ---")
        if SyncManager.sharedInstance.sync(self.user!) != nil {
            rejectAndResetSyncCallbacks("SyncManager failed to regulate sequential syncs, all pending syncs have been rejected")
        }
    }

    fileprivate func bindEvents() {
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted, completion: {
            (event) in
            print("--- [WvConfig] received sync complete from SyncManager ---")

            self.resolveSync()
        })

        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed, completion: {
            (event) in
            print("--- [WvConfig] reveiced sync FAILED from SyncManager ---")
            self.showStatusMessage(.syncError, error: (event.eventData as? [String:Any])?["error"] as? Error)

            self.rejectAndResetSyncCallbacks("SyncManager failed to complete the sync, all pending syncs have been rejected")
        })
    }

    fileprivate func getWVResponse(_ response:WVResponse, message:String?) -> String {
        switch response {
        case .success:
            return response.rawValue
        case .failed:
            if let reason = message {
                return String(format: response.rawValue, reason)
            }
            return String(format: response.rawValue, "unknown")
        case .successStillWorking:
            if let count = message {
                return String(format: response.rawValue, count)
            }
            return String(format: response.rawValue, "unknown")
        case .noSessionData:
            return response.rawValue
        }
    }

    @objc fileprivate func logout() {
        if let _ = user {
            self.webview!.evaluateJavaScript("window.RtmBridge.forceLogout()") { (result, error) in
                if error != nil {
                    print("failed to log out user through window.RtmBridge.logout")
                }
            }
        }
    }

}

