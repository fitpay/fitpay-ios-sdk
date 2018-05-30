import Foundation
import WebKit

class WvConfig: NSObject, WKScriptMessageHandler {
    
    weak var rtmDelegate: RTMDelegate? {
        didSet {
            self.rtmMessaging.rtmDelegate = rtmDelegate
        }
    }
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate? {
        didSet {
            self.rtmMessaging.cardScannerPresenterDelegate = cardScannerPresenterDelegate
        }
    }
    weak var cardScannerDataSource: FitpayCardScannerDataSource? {
        didSet {
            self.rtmMessaging.cardScannerDataSource = cardScannerDataSource
        }
    }

    weak var a2aVerificationDelegate: FitpayA2AVerificationDelegate? {
        didSet {
            self.rtmMessaging.a2aVerificationDelegate = a2aVerificationDelegate
        }
    }

    var user: User? {
        get {
            return self.configStorage.user
        }
        set {
            self.configStorage.user = newValue
        }
    }
    
    var device: DeviceInfo? {
        get {
            return self.configStorage.device
        }
        set {
            self.configStorage.device = newValue
        }
    }

     var a2aReturnLocation: String? {
        get {
            return self.configStorage.a2aReturnLocation
        }
        set {
            self.configStorage.a2aReturnLocation = newValue
        }
    }
    
    //MARK: - and Private Variables
    
    var configStorage = WvConfigStorage()

    var url = FitpayConfig.webURL
    
    var webview: WKWebView?
    var connectionBinding: FitpayEventBinding?
    var sessionDataCallBack: RtmMessage?
    var syncCallBacks = [RtmMessage]()
    
    private var bindings: [FitpayEventBinding] = []
    private var rtmVersionSent = false
    
    //MARK: - Lifecycle
    
    convenience init(paymentDevice: PaymentDevice, userEmail: String?, isNewAccount: Bool) {
        self.init(paymentDevice: paymentDevice, rtmConfig: RtmConfig(userEmail: userEmail, deviceInfo: nil, hasAccount: !isNewAccount))
    }
    
    init(paymentDevice: PaymentDevice, rtmConfig: RtmConfigProtocol) {
        self.configStorage.paymentDevice = paymentDevice
        self.configStorage.rtmConfig = rtmConfig
        self.url = FitpayConfig.webURL
        
        self.rtmMessaging = RtmMessaging(wvConfigStorage: self.configStorage)
        
        super.init()
        
        self.rtmMessaging.outputDelagate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        self.bindEvents()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.webview?.configuration.userContentController.removeScriptMessageHandler(forName: "rtmBridge")
        self.unbindEvents()
    }
    
    //MARK: - Public Functions
    
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
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let sentData = message.body as? [String: Any] else {
            log.error("WV_DATA: Received message from \(message.name), but can't convert it to dictionary type.")
            return
        }

        self.rtmMessaging.received(message: sentData)
    }
    
    // MARK: - Internal
    
    /**
     In order to open a web-view the SDK must have a connection to the payment device in order to gather data about
     that device. This will attempt to connect, and call the completion with either an error or nil if the connection
     attempt is successful.
     */
    func openDeviceConnection(_ completion: @escaping (_ error: NSError?) -> Void) {
        self.connectionBinding = self.configStorage.paymentDevice!.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected) { [weak self] (event) in
            guard let strongSelf = self else { return }
            
            strongSelf.configStorage.paymentDevice!.removeBinding(binding: strongSelf.connectionBinding!)
            
            if let error = (event.eventData as? [String: Any])?["error"] as? NSError {
                completion(error)
                return
            }
            
            if let deviceInfo = (event.eventData as? [String: Any])?["deviceInfo"] as? DeviceInfo {
                strongSelf.configStorage.rtmConfig?.deviceInfo = deviceInfo
                completion(nil)
                return
            }
            
            completion(NSError.error(code:WvConfig.ErrorCode.deviceDataNotValid, domain: WvConfig.self))
        }
        
        self.configStorage.paymentDevice!.connect()
    }
    
    /**
     Sets webview which will be used by fitpay platform.
     Make sure that webViewPageLoaded() will be called, otherwise RTM will not work.
     */
    func setWebView(_ webview: WKWebView!) {
        guard self.webview != webview else { return }
        
        self.rtmVersionSent = false
        self.webview = webview
    }
    
    /**
     Should be called when webview will be loaded.
     You can use WKNavigationDelegate.webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) for managing page state.
     */
    func webViewPageLoaded() {
        if !rtmVersionSent {
            sendVersion(version: RtmProtocolVersion.currentlySupportedVersion())
        }
    }
    
    /**
     This returns the configuration for a WKWebView that will enable the iOS rtm bridge in the web app. Note that
     the value "rtmBridge" is an agreeded upon value between this and the web-view.
     */
    func getConfig() -> WKWebViewConfiguration {
        
        class LeakAvoider: NSObject, WKScriptMessageHandler {
            weak var delegate: WKScriptMessageHandler?
            
            init(delegate: WKScriptMessageHandler) {
                self.delegate = delegate
                super.init()
            }
            
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                self.delegate?.userContentController(userContentController, didReceive: message)
            }
        }
        
        let config = WKWebViewConfiguration()
        config.userContentController.add(LeakAvoider(delegate: self), name: "rtmBridge")
        
        return config
    }
    
    /**
     This returns the request object clients will require in order to open a WKWebView
     */
    func getRequest() -> URLRequest {
        if let accessToken = self.configStorage.user?.client?._session.accessToken {
            self.configStorage.rtmConfig!.accessToken = accessToken
        }
        
        if self.configStorage.rtmConfig?.deviceInfo?.notificationToken == nil && FitpayNotificationsManager.sharedInstance.notificationsToken.isEmpty == false {
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
    
    func getURLAndConfig() -> (url: String, encodedConfig: String)? {
        if let accessToken = self.configStorage.user?.client?._session.accessToken {
            self.configStorage.rtmConfig!.accessToken = accessToken
        }
        
        if self.configStorage.rtmConfig?.deviceInfo?.notificationToken == nil && FitpayNotificationsManager.sharedInstance.notificationsToken.isEmpty == false {
            self.configStorage.rtmConfig?.deviceInfo?.notificationToken = FitpayNotificationsManager.sharedInstance.notificationsToken
        }
        
        let JSONString = self.configStorage.rtmConfig?.jsonDict().JSONString
        let utfString = JSONString?.data(using: String.Encoding.utf8, allowLossyConversion: true)
        
        guard let encodedConfig = utfString?.base64URLencoded() else { return nil}
        
        return (url, encodedConfig)
    }
    
    func showStatusMessage(_ status: WVDeviceStatus, message: String? = nil, error: Error? = nil) {
        var realMessage = message ?? status.defaultMessage()
        if let newMessage = rtmDelegate?.willDisplayStatusMessage?(status, defaultMessage: realMessage, error: error as NSError?) {
            realMessage = newMessage
        }
        
        sendStatusMessage(realMessage, type: status.statusMessageType())
    }
    
    func sendRtmMessage(rtmMessage: RtmMessageResponse, retries: Int = 3) {
        guard let jsonRepresentation = rtmMessage.toJSONString() else {
            log.error("WV_DATA: Can't create json representation for rtm message.")
            return
        }

        log.debug("WV_DATA: sending data to wv: \(jsonRepresentation)")
        
        webview?.evaluateJavaScript("window.RtmBridge.resolve(\(jsonRepresentation))", completionHandler: { [weak self] (result, error) in
            if let error = error {
                if retries > 0 {
                    log.warning("WV_DATA: Can't send message to wv... retrying...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.sendRtmMessage(rtmMessage: rtmMessage, retries: retries - 1)
                    }
                } else {
                    log.error("WV_DATA: Can't send message to wv, error: \(error)")
                }
            }
        })
    }

    func sendStatusMessage(_ message: String, type: WVMessageType) {
        sendRtmMessage(rtmMessage: self.rtmMessaging.messageHandler?.statusResponseMessage(message: message, type: type) ?? RtmMessageResponse(data:["message": message, "type": type.rawValue], type: "deviceStatus"))
    }
    
    //MARK: - Private
    
    private var rtmMessaging: RtmMessaging
    
    private func resolveSync() {
        self.rtmMessaging.messageHandler?.resolveSync()
    }
    
    private func sendVersion(version: RtmProtocolVersion) {
        sendRtmMessage(rtmMessage: self.rtmMessaging.messageHandler?.versionResponseMessage(version: version) ?? RtmMessageResponse(data: ["version":version.rawValue], type: "version"))
        rtmVersionSent = true
    }

    private func bindEvents() {
        var binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: .syncStarted) { [weak self] (event) in
            self?.showStatusMessage(.syncGettingUpdates)
        }
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
        
        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted) { [weak self] (event) in
            log.debug("WV_DATA: received sync complete from SyncManager.")
            
            self?.resolveSync()
            self?.showStatusMessage(.syncComplete)
        }
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
        
        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed) { [weak self] (event) in
            log.error("WV_DATA: received sync FAILED from SyncManager.")
            let error = (event.eventData as? [String:Any])?["error"] as? NSError
            
            if error?.code == SyncManager.ErrorCode.cantConnectToDevice.rawValue {
                self?.showStatusMessage(.syncUpdatingConnectionFailed)
            } else {
                self?.showStatusMessage(.syncError, error: (event.eventData as? [String:Any])?["error"] as? Error)
            }
        }
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
        
        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: .commitsReceived) { [weak self] (event) in
            guard let commits = (event.eventData as! [String:[Commit]])["commits"] else {
                self?.showStatusMessage(.syncNoUpdates)
                return
            }
            if commits.count > 0 {
                self?.showStatusMessage(.syncUpdating)
            } else {
                self?.showStatusMessage(.syncNoUpdates)
            }
        }
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }

        binding = SyncManager.sharedInstance.bindToSyncEvent(eventType: .connectingToDevice) { [weak self] (event) in
            self?.showStatusMessage(.syncUpdatingConnectingToDevice)
        }
        
        if let nonOptionalBinding = binding {
            self.bindings.append(nonOptionalBinding)
        }
    }
    
    private func unbindEvents() {
        for binding in self.bindings {
            SyncManager.sharedInstance.removeSyncBinding(binding: binding)
        }
    }

    @objc private func logout() {
        if let _ = self.configStorage.user {
            sendRtmMessage(rtmMessage: self.rtmMessaging.messageHandler?.logoutResponseMessage() ?? RtmMessageResponse(type: "logout"))
        }
    }
}

extension WvConfig: RtmOutputDelegate {
    
    func send(rtmMessage: RtmMessageResponse, retries: Int) {
        self.sendRtmMessage(rtmMessage: rtmMessage, retries: retries)
    }
    
    func show(status: WVDeviceStatus, message: String?, error: Error?) {
        self.showStatusMessage(status, message: message, error: error)
    }
    
}

//MARK: - Enums

extension WvConfig {
    
   enum WVMessageType: Int {
        case error = 0
        case success
        case progress
        case pending
    }

    enum RtmProtocolVersion: Int {
        case ver1 = 1
        case ver2
        case ver3
        case ver4
        case ver5
        
        static func currentlySupportedVersion() -> RtmProtocolVersion {
            return .ver5
        }
    }
    
    enum ErrorCode: Int, RawIntValue, Error, CustomStringConvertible {
        case unknownError       = 0
        case deviceDataNotValid = 10002
        
        var description: String {
            switch self {
            case .unknownError:
                return "Unknown error"
            case .deviceDataNotValid:
                return "Could not open connection. OnDeviceConnected event did not supply valid device data."
            }
        }
    }
    

    // These responses must conform to what is expected by the web-view. Changing their structure also requires
    // changing them in the rtmIosImpl.js
    enum WVResponse: Int {
        case success = 0
        case failed
        case successStillWorking
        case noSessionData
        
        func dictionaryRepresentation(param: Any? = nil) -> [String: Any] {
            switch self {
            case .success, .noSessionData:
                return ["status": rawValue]
            case .failed:
                return ["status": rawValue, "reason": param ?? "unknown"]
            case .successStillWorking:
                return ["status": rawValue, "count": param ?? "unknown"]
            }
        }
    }

    
}
