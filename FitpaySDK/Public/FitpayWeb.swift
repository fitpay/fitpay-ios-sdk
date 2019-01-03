import Foundation
import WebKit

/// Main Object for interacting with Fitpay Web app
@objc open class FitpayWeb: NSObject {
    
    /// Use this singleton unless you have a reason for multiple webviews
    @objc public static let shared = FitpayWeb()

    /// Set the rtmDelegate to receive authorization and other messages from the webview
    ///
    /// Needed for capturing a back button press
    @objc weak open var rtmDelegate: RTMDelegate? {
        didSet {
            wvConfig.rtmDelegate = rtmDelegate
        }
    }
    
    /// Set the a2aVerificationDelegate to handle step up methods using the issuer app
    @objc weak open var a2aVerificationDelegate: FitpayA2AVerificationDelegate? {
        didSet {
            wvConfig.a2aVerificationDelegate = a2aVerificationDelegate
        }
    }
    
    /// Set the cardScannerDataSource to handle step up methods using the issuer app
    @objc weak open var cardScannerDataSource: FitpayCardScannerDataSource? {
        didSet {
            wvConfig.cardScannerDataSource = cardScannerDataSource
        }
    }
    
    /// Set the cardScannerPresenterDelegate to handle step up methods using the issuer app
    @objc weak open var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate? {
        didSet {
            wvConfig.cardScannerPresenterDelegate = cardScannerPresenterDelegate
        }
    }
    
    private var wkWebView: WKWebView!
    private var wvConfig: WvConfig!
    
    // MARK: - Functions
    
    /// Setup a Fitpay WKWebview for use
    ///
    /// You must use WKWebview returned by this function
    ///
    /// This must be called before any other methods
    ///
    /// - Parameters:
    ///   - userEmail: user email - defaults to nil
    ///   - userHasFitpayAccount: user has fitpayAccount - defaults to false
    ///   - accessToken: skips the pin screen if valid
    ///   - paymentDevice: figuring out
    ///   - paymentDeviceConnector: figuring out
    ///   - frame: needed for initializing the wkWebView
    ///   - script: script to be passed to `addUserScript` to perform actions like preventing zoom
    ///   - language: language for text to be displayed in
    /// - Returns: WKWebview with correct configuration and frame
    @objc open func setupWebView(userEmail: String? = nil,
                                 userHasFitpayAccount: Bool = false,
                                 accessToken: String? = nil,
                                 paymentDevice: PaymentDevice,
                                 paymentDeviceConnector: PaymentDeviceConnectable,
                                 frame: CGRect,
                                 script: WKUserScript? = nil,
                                 language: String? = nil) -> WKWebView {

        _ = paymentDevice.changeDeviceInterface(paymentDeviceConnector)

        let rtmConfig = RtmConfig(userEmail: userEmail, deviceInfo: paymentDeviceConnector.deviceInfo())
        rtmConfig.hasAccount = userHasFitpayAccount
        rtmConfig.language = language
        rtmConfig.accessToken = accessToken
        
        wvConfig = WvConfig(paymentDevice: paymentDevice, rtmConfig: rtmConfig)

        let config = wvConfig!.getConfig()
        if let script = script {
            config.userContentController.addUserScript(script)
        }
        wkWebView = WKWebView(frame: frame, configuration: config)
        
        wvConfig!.setWebView(wkWebView)
        
        wkWebView!.navigationDelegate = self
        
        return wkWebView!
    }

    /// Loads the main page on Fitpay based on user variables
    @objc open func load() {
        wkWebView.load(wvConfig.getRequest())
    }
    
    /// Loads a specific page on Fitpay based on `FitpayConfig.WebUrl` and passed in route
    open func load(relativePath: String) {
        guard let encodedConfig = wvConfig.getEncodedConfig() else { return }
        
        let configuredUrl = "\(relativePath)?config=\(encodedConfig)"
        
        log.verbose("WV: loading \(configuredUrl)")
        
        let requestUrl = URL(string: configuredUrl)
        let request = URLRequest(url: requestUrl!)
        
        wkWebView.load(request)
    }
    
    /// Loads a specific page on Fitpay based on `FitpayConfig.WebUrl` and passed in route
    @available(*, deprecated, message: "as of v1.5.3 ...")
    open func load(relativePath: RelativeWebPath) {
        guard let encodedConfig = wvConfig.getEncodedConfig() else { return }
        
        let configuredUrl = "\(FitpayConfig.webURL)\(relativePath.rawValue)?config=\(encodedConfig)"
        
        log.verbose("WV: loading \(configuredUrl)")
        
        let requestUrl = URL(string: configuredUrl)
        let request = URLRequest(url: requestUrl!)
        
        wkWebView.load(request)
    }
    
    /// Loads any valid url - use with discretion
    ///
    /// Can construct URL from any valid string. Must include config manually.
    @objc open func load(absolutePath: String) {
        let requestUrl = URL(string: absolutePath)
        let request = URLRequest(url: requestUrl!)
        
        log.verbose("WV: loading \(absolutePath)")
        
        wkWebView.load(request)
    }
    
    /// Loads links returned from User and CreditCard object
    open func load(link: Link) {
        guard let encodedConfig = wvConfig.getEncodedConfig() else { return }
        var url = link.href
        
        if link.templated == true {
            url = url.replacingOccurrences(of: "{config}", with: encodedConfig)
        }
        
        log.verbose("WV: loading \(url)")
        
        let requestUrl = URL(string: url)
        let request = URLRequest(url: requestUrl!)
        
        wkWebView.load(request)
    }
    
    /// Loads the correct url based on the issuers response
    ///
    /// You should still call respondToA2AWith(success:error:)
    @objc open func load(issuerResponse: A2AIssuerResponse) {
        guard let encodedConfig = wvConfig.getEncodedConfig(),
            let returnLocation = wvConfig.a2aReturnLocation,
            let encodedIssuerResponse = issuerResponse.getEncodedString() else { return }
        
        let configuredUrl = "\(FitpayConfig.webURL)\(returnLocation)?a2a=\(encodedIssuerResponse)&config=\(encodedConfig)"
        
        log.verbose("WV: loading \(configuredUrl)")
        
        let requestUrl = URL(string: configuredUrl)
        let request = URLRequest(url: requestUrl!)
        
        wkWebView.load(request)
    }
    
    /// Get the config to construct a url on your own if needed
    @objc open func getConfig() -> String? {
        return wvConfig.getEncodedConfig()
    }
    
    /// Should be called once the webview is loaded
    ///
    /// This is called automatically unless you become the navigationDelegate in which case you must set it manually
    ///
    /// You can use `WKNavigationDelegate.webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)` for managing page state
    @objc open func webViewPageLoaded() {
         wvConfig.webViewPageLoaded()
    }
 
    /// Used to tell the webview if A2A completed successfully or not
    open func respondToA2AWith(success: Bool, error: A2AVerificationError?) {
        wvConfig.rtmMessaging.messageHandler?.appToAppVerificationResponse(success: success, reason: error)
    }
    
}

extension FitpayWeb: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewPageLoaded()
    }
    
}
