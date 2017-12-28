
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
    case ver3
    case ver4
    case ver5
    
    static func currentlySupportedVersion() -> RtmProtocolVersion {
        return .ver5
    }
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

class WvConfigStorage {
    var sdkConfiguration: FitpaySDKConfiguration?
    var paymentDevice: PaymentDevice?
    var user: User?
    var device: DeviceInfo?
    
    var rtmConfig: RtmConfigProtocol?
}

@objc open class WvConfig : NSObject, WKScriptMessageHandler {
    public enum ErrorCode : Int, Error, RawIntValue, CustomStringConvertible
    {
        case unknownError                   = 0
        case deviceDataNotValid				= 10002
        
        public var description : String {
            switch self {
            case .unknownError:
                return "Unknown error"
            case .deviceDataNotValid:
                return "Could not open connection. OnDeviceConnected event did not supply valid device data."
            }
        }
    }
    
    weak open var rtmDelegate : WvRTMDelegate? {
        didSet {
            self.rtmMessaging.rtmDelegate = rtmDelegate
        }
    }
    weak open var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate? {
        didSet {
            self.rtmMessaging.cardScannerPresenterDelegate = cardScannerPresenterDelegate
        }
    }
    weak open var cardScannerDataSource: FitpayCardScannerDataSource? {
        didSet {
            self.rtmMessaging.cardScannerDataSource = cardScannerDataSource
        }
    }

    var url = BASE_URL
    let notificationCenter = NotificationCenter.default
    
    var webview: WKWebView?
    var connectionBinding: FitpayEventBinding?
    var sessionDataCallBack: RtmMessage?
    var syncCallBacks = [RtmMessage]()

    public var user: User? {
        get {
            return self.configStorage.user
        }
        set {
            self.configStorage.user = newValue
        }
    }
    
    public var device: DeviceInfo? {
        get {
            return self.configStorage.device
        }
        set {
            self.configStorage.device = newValue
        }
    }
    
    var configStorage = WvConfigStorage()
    
    private var bindings: [FitpayEventBinding] = []

    fileprivate var rtmVersionSent = false
    
    @objc open var demoModeEnabled : Bool {
        get {
            if let isEnabled = self.configStorage.rtmConfig?.jsonDict()[RtmConfigDafaultMappingKey.demoMode.rawValue] as? Bool {
                return isEnabled
            }
            return false
        }
        set {
            self.configStorage.rtmConfig?.update(value: newValue, forKey: RtmConfigDafaultMappingKey.demoMode.rawValue)
        }
    }
    
    @objc public convenience init(clientId:String, redirectUri:String, paymentDevice:PaymentDevice, userEmail:String?, isNewAccount:Bool) {
        self.init(paymentDevice: paymentDevice, rtmConfig: RtmConfig(clientId: clientId, redirectUri: redirectUri, userEmail: userEmail, deviceInfo: nil, hasAccount: !isNewAccount), SDKConfiguration: FitpaySDKConfiguration(clientId: clientId, redirectUri: redirectUri, baseAuthURL: AUTHORIZE_BASE_URL, baseAPIURL: API_BASE_URL))
    }
    
    @objc public init(paymentDevice:PaymentDevice, rtmConfig: RtmConfigProtocol, SDKConfiguration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration) {
        self.configStorage.paymentDevice = paymentDevice
        self.configStorage.rtmConfig = rtmConfig
        self.configStorage.sdkConfiguration = SDKConfiguration
        self.url = SDKConfiguration.webViewURL
        
        self.rtmMessaging = RtmMessaging(wvConfigStorage: self.configStorage)

        super.init()
        
        self.rtmMessaging.outputDelagate = self
        
        self.demoModeEnabled = false

        self.notificationCenter.addObserver(self, selector: #selector(logout), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        self.bindEvents()
    }

    deinit {
        self.notificationCenter.removeObserver(self)
        self.webview?.configuration.userContentController.removeScriptMessageHandler(forName: "rtmBridge")
        self.unbindEvents()
    }
    
    /**
      In order to open a web-view the SDK must have a connection to the payment device in order to gather data about 
      that device. This will attempt to connect, and call the completion with either an error or nil if the connection 
      attempt is successful.
     */
    @objc open func openDeviceConnection(_ completion: @escaping (_ error:NSError?) -> Void) {
        self.connectionBinding = self.configStorage.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected, completion: {
            [weak self] (event) in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.configStorage.paymentDevice!.removeBinding(binding: strongSelf.connectionBinding!)

            if let error = (event.eventData as! [String: Any])["error"] as? NSError {
                completion(error)
                return
            }

            if let deviceInfo = (event.eventData as! [String: Any])["deviceInfo"] as? DeviceInfo {
                strongSelf.configStorage.rtmConfig?.deviceInfo = deviceInfo
                completion(nil)
                return
            }
            
            completion(NSError.error(code:WvConfig.ErrorCode.deviceDataNotValid, domain: WvConfig.self))
        })
        
        self.configStorage.paymentDevice!.connect()
    }
    
    /**
     Sets webview which will be used by fitpay platform.
     Make sure that webViewPageLoaded() will be called, otherwise RTM will not work.
     */
    @objc open func setWebView(_ webview:WKWebView!) {
        guard self.webview != webview else {
            return
        }
        
        self.rtmVersionSent = false
        self.webview = webview
    }
    
    /**
     Should be called when webview will be loaded.
     You can use WKNavigationDelegate.webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) for managing page state.
     */
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
        if let accessToken = self.configStorage.user?.client?._session.accessToken {
            self.configStorage.rtmConfig!.accessToken = accessToken
        }
        
        if self.configStorage.rtmConfig?.deviceInfo?.notificationToken == nil && FitpayNotificationsManager.sharedInstance.notificationsToken.characters.count > 0 {
            self.configStorage.rtmConfig?.deviceInfo?.notificationToken = FitpayNotificationsManager.sharedInstance.notificationsToken
        }
        
        let JSONString = self.configStorage.rtmConfig?.jsonDict().JSONString
        let utfString = JSONString?.data(using: String.Encoding.utf8, allowLossyConversion: true)
        let encodedConfig = utfString?.base64URLencoded()
        let configuredUrl = "\(url)?config=\(encodedConfig ?? "cantGenerateConfig_badJson?")"
        
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

        self.rtmMessaging.received(message: sentData)
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
    
    @objc open func sendRtmMessage(rtmMessage: RtmMessageResponse, retries: Int = 3) {
        guard let jsonRepresentation = rtmMessage.toJSONString(prettyPrint: false) else {
            log.error("WV_DATA: Can't create json representation for rtm message.")
            return
        }

        log.debug("WV_DATA: sending data to wv: \(jsonRepresentation)")
        
        webview?.evaluateJavaScript("window.RtmBridge.resolve(\(jsonRepresentation))", completionHandler: { [weak self] (result, error) in
            if let error = error {
                if retries > 0 {
                    log.warning("WV_DATA: Can't send message to wv... retrying...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self?.sendRtmMessage(rtmMessage: rtmMessage, retries: retries - 1)
                    })
                } else {
                    log.error("WV_DATA: Can't send message to wv, error: \(error)")
                }
            }
        })
    }
    
    fileprivate var rtmMessaging: RtmMessaging
    
    fileprivate func sendStatusMessage(_ message: String, type: WVMessageType) {
        sendRtmMessage(rtmMessage: self.rtmMessaging.messageHandler?.statusResponseMessage(message: message, type: type) ?? RtmMessageResponse(data:["message":message, "type":type.rawValue], type: "deviceStatus"))
    }

    fileprivate func resolveSync() {
        self.rtmMessaging.messageHandler?.resolveSync()
    }
    
    fileprivate func sendVersion(version: RtmProtocolVersion) {
        sendRtmMessage(rtmMessage: self.rtmMessaging.messageHandler?.versionResponseMessage(version: version) ?? RtmMessageResponse(data: ["version":version.rawValue], type: "version"))
        rtmVersionSent = true
    }

    fileprivate func bindEvents() {
        var binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: .syncStarted, completion: { [weak self] (event) in
            self?.showStatusMessage(.syncGettingUpdates)
        })
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
        
        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted, completion: { [weak self] (event) in
            log.debug("WV_DATA: received sync complete from SyncManager.")
            
            self?.resolveSync()
            self?.showStatusMessage(.syncComplete)
        })
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
        
        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed, completion: { [weak self] (event) in
            log.error("WV_DATA: received sync FAILED from SyncManager.")
            let error = (event.eventData as? [String:Any])?["error"] as? NSError
            
            if error?.code == SyncManager.ErrorCode.cantConnectToDevice.rawValue {
                self?.showStatusMessage(.syncUpdatingConnectionFailed)
            } else {
                self?.showStatusMessage(.syncError, error: (event.eventData as? [String:Any])?["error"] as? Error)
            }
            
        })
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
        
        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: .commitsReceived, completion: { [weak self] (event) in
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
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
    }
    
    fileprivate func unbindEvents() {
        for binding in self.bindings {
            SyncManager.sharedInstance.removeSyncBinding(binding: binding)
        }
    }

    @objc fileprivate func logout() {
        if let _ = self.configStorage.user {
            sendRtmMessage(rtmMessage: self.rtmMessaging.messageHandler?.logoutResponseMessage() ?? RtmMessageResponse(type: "logout"))
        }
    }
}

extension WvConfig: RtmOutputDelegate {
    func send(rtmMessage: RtmMessageResponse, retries: Int) {
        self.sendRtmMessage(rtmMessage: rtmMessage, retries: retries)
    }
    
    func show(status: WVDeviceStatuses, message: String?, error: Error?) {
        self.showStatusMessage(status, message: message, error: error)
    }
}
