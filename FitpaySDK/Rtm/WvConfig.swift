
import Foundation
import WebKit
import ObjectMapper


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


public class WvConfig : NSObject, WKScriptMessageHandler {

    var url = BASE_URL
    let paymentDevice: PaymentDevice?
    let restSession: RestSession?
    let restClient: RestClient?
    let notificationCenter = NSNotificationCenter.defaultCenter()

    public var user: User?
    var rtmConfig: RtmConfig?
    var webViewSessionData: WebViewSessionData?
    var webview: WKWebView?
    var connectionBinding: FitpayEventBinding?
    var sessionDataCallBackId: Int?
    var syncCallBacks = [Int]()
    
    public convenience init(clientId:String, redirectUri:String, paymentDevice:PaymentDevice, userEmail:String?) {
        self.init(paymentDevice: paymentDevice, userEmail: userEmail, SDKConfiguration: FitpaySDKConfiguration(clientId: clientId, redirectUri: redirectUri, authorizeURL: AUTHORIZE_URL, baseAPIURL: API_BASE_URL))
    }
    
    public init(paymentDevice:PaymentDevice, userEmail:String?, SDKConfiguration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration) {
        self.paymentDevice = paymentDevice
        self.rtmConfig = RtmConfig(clientId: SDKConfiguration.clientId, redirectUri: SDKConfiguration.redirectUri, userEmail: userEmail, deviceInfo: nil)
        self.restSession = RestSession(configuration: SDKConfiguration)
        self.restClient = RestClient(session: self.restSession!)
        self.paymentDevice!.deviceInfo?.client = self.restClient
        
        self.url = SDKConfiguration.webViewURL
        
        SyncManager.sharedInstance.paymentDevice = paymentDevice
        
        super.init()
        
        self.notificationCenter.addObserver(self, selector: #selector(logout), name: UIApplicationWillEnterForegroundNotification, object: nil)
        self.bindEvents()
    }

    /**
      In order to open a web-view the SDK must have a connection to the payment device in order to gather data about 
      that device. This will attempt to connect, and call the completion with either an error or nil if the connection 
      attempt is successful.
     */
    public func openDeviceConnection(completion: (error:NSError?) -> Void) {
        self.connectionBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceConnected, completion: {
            (event) in
            
            self.paymentDevice!.removeBinding(binding: self.connectionBinding!)

            if let error = event.eventData["error"]! as? NSError {
                completion(error: error)
                return
            }

            if let deviceInfo = event.eventData["deviceInfo"]! as? DeviceInfo {
                self.rtmConfig?.deviceInfo = deviceInfo
                completion(error: nil)
                return
            }

            completion(error: NSError.error(code: 1, domain: WvConfig.self, message: "Could not open connection. OnDeviceConnected event did not supply valid device data"))
        })
        
        self.paymentDevice!.connect()
    }
    
    public func setWebView(webview:WKWebView!) {
        self.webview = webview
    }
    
    /**
     This returns the configuration for a WKWebView that will enable the iOS rtm bridge in the web app. Note that
     the value "rtmBridge" is an agreeded upon value between this and the web-view.
     */
    public func wvConfig() -> WKWebViewConfiguration {
        let config:WKWebViewConfiguration = WKWebViewConfiguration()
        config.userContentController.addScriptMessageHandler(self, name: "rtmBridge")
        
        return config
    }
    
    /**
     This returns the request object clients will require in order to open a WKWebView
     */
    public func wvRequest() -> NSURLRequest {
        let JSONString = Mapper().toJSONString(rtmConfig!)
        let utfString = JSONString!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let encodedConfig = utfString?.base64URLencoded()
        let configuredUrl = "\(url)?config=\(encodedConfig! as String)"
        
        print(configuredUrl)
        
        let requestUrl = NSURL(string: configuredUrl)
        let request = NSURLRequest(URL: requestUrl!)
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
    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let sentData = message.body as! NSDictionary

        if sentData["data"]!["action"] as! String == "sync" {
            print("received sync message from web-view")
            handleSync(sentData["callBackId"] as! Int)
        } else if sentData["data"]!["action"] as! String == "userData" {
            print("received user session data from web-view")

            sessionDataCallBackId = sentData["callBackId"] as? Int

            do {
                let data = sentData["data"]!["data"]!
                let jsonData = try NSJSONSerialization.dataWithJSONObject(data!, options: NSJSONWritingOptions.PrettyPrinted)
                let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
                let webViewSessionData = Mapper<WebViewSessionData>().map(jsonString)

                handleSessionData(webViewSessionData!)
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    private func handleSync(callBackId:Int) -> Void {
        if (self.webViewSessionData != nil && self.user != nil ) {
            syncCallBacks.append(callBackId)

            if !SyncManager.sharedInstance.isSyncing {
                goSync()
            }
        } else {
            self.callBack(
                self.syncCallBacks.first!,
                success: false,
                response: self.getWVResponse(WVResponse.noSessionData, message: nil))
        }
    }
    
    private func handleSessionData(webViewSessionData:WebViewSessionData) -> Void {
        self.webViewSessionData = webViewSessionData
        self.restSession!.setWebViewAuthorization(webViewSessionData)

        restClient?.user(id: (self.webViewSessionData?.userId)!, completion: {
            (user, error) in
            
            guard (error == nil || user == nil) else {
                self.callBack(
                    self.sessionDataCallBackId!,
                    success: false,
                    response: self.getWVResponse(WVResponse.failed, message: error.debugDescription))

                return
            }

            self.user = user

            self.callBack(
                self.sessionDataCallBackId!,
                success: true,
                response: self.getWVResponse(WVResponse.success, message: nil))
        })
    }

    private func rejectAndResetSyncCallbacks(reason:String) {
        for cbId in self.syncCallBacks {
            callBack(
                cbId,
                success: false,
                response: getWVResponse(WVResponse.failed, message: reason))
        }

        self.syncCallBacks = [Int]()
    }

    private func resolveSync() {
        if let id = self.syncCallBacks.first {
            if self.syncCallBacks.count > 1 {
                self.callBack(
                    id,
                    success: true,
                    response: getWVResponse(WVResponse.successStillWorking, message: "\(self.syncCallBacks.count)"))

                goSync()
            } else {
                self.callBack(
                    id,
                    success: true,
                    response: getWVResponse(WVResponse.success, message: nil))
            }

            self.syncCallBacks.removeFirst()
        } else {
            print("no callbacks available for sync resolution")
        }
    }

    private func callBack(callBackId:Int, success:Bool, response:String) {
        self.webview!.evaluateJavaScript("window.RtmBridge.resolve(\(callBackId), \(success), \(response))", completionHandler: {
            (result, error) in

            if error != nil {
                print("error")
            }
        })
    }

    private func goSync() {
        if SyncManager.sharedInstance.sync(self.user!) != nil {
            rejectAndResetSyncCallbacks("SyncManager failed to regulate sequential syncs, all pending syncs have been rejected")
        }
    }

    private func bindEvents() {
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_COMPLETED, completion: {
            (event) in

            self.resolveSync()
        })

        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_FAILED, completion: {
            (event) in

            self.rejectAndResetSyncCallbacks("SyncManager failed to complete the sync, all pending syncs have been rejected")
        })
    }

    private func getWVResponse(response:WVResponse, message:String?) -> String {
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

    @objc private func logout() {
        self.webview!.evaluateJavaScript("window.RtmBridge.forceLogout()") { (result, error) in
            if error != nil {
                print("failed to log out user through window.RtmBridge.logout")
            }
        }
    }

}

