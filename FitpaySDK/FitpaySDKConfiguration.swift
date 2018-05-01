import Foundation

internal let log = FitpaySDKLogger.sharedInstance

open class FitpaySDKConfiguration: NSObject {
    open static let defaultConfiguration = FitpaySDKConfiguration()
    
    open var clientId: String
    open var redirectUri: String
    open var baseAuthURL: String
    open var baseAPIURL: String
    open var webViewURL: String
    
    open var commitProcessingTimeoutSecs: Double = 30.0
    
    open static let sdkVersion = Bundle(for: FitpaySDKConfiguration.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "unk"
    
    // MARK: - Lifecycle
    
    override public init() {
        self.clientId = ""
        self.redirectUri = BASE_URL
        self.baseAuthURL = AUTHORIZE_BASE_URL
        self.baseAPIURL = API_BASE_URL
        self.webViewURL = BASE_URL
        
        super.init()
        
        self.setupLogs()
    }
    
    public init(clientId: String, redirectUri: String, baseAuthURL: String, baseAPIURL: String, webViewURL: String = BASE_URL) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.baseAuthURL = baseAuthURL
        self.baseAPIURL = baseAPIURL
        self.webViewURL = webViewURL
        
        super.init()
        
        self.setupLogs()
    }
    
    // MARK: - Functions
    
    open func loadEnvironmentVariables() -> Error? {
        let envDict = ProcessInfo.processInfo.environment

        //clientId checks
        guard let clientId = envDict["SDK_CLIENT_ID"], !clientId.isEmpty else {
            return EnvironmentLoadingErrors.clientIdIsEmpty
        }
        
        //baseAPIUrl checks
        guard let baseAPIUrl = envDict["SDK_API_BASE_URL"], !baseAPIUrl.isEmpty else {
            return EnvironmentLoadingErrors.baseApiUrlIsEmpty
        }
        
        //baseAuthBaseUrl checks
        guard let baseAuthBaseUrl = envDict["SDK_AUTHORIZE_BASE_URL"], !baseAuthBaseUrl.isEmpty else {
            return EnvironmentLoadingErrors.authorizeURLIsEmpty
        }
        
        self.clientId = clientId
        self.baseAuthURL = baseAuthBaseUrl
        self.baseAPIURL = baseAPIUrl
        
        return nil
    }
    
    // MARK: - Internal / Private

    private func setupLogs() {
        log.addOutput(output: ConsoleOutput())
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "Use commitProcessingTimeoutSecs")
    open var commitErrorTimeout: Int {
        set {
            commitProcessingTimeoutSecs = Double(newValue)
        }
        get {
            return Int(commitProcessingTimeoutSecs)
        }
    }
    
    //MARK: - Nested Objects
    
    enum EnvironmentLoadingErrors: Error {
        case clientIdIsEmpty
        case clientSecretIsEmpty
        case baseApiUrlIsEmpty
        case authorizeURLIsEmpty
    }
    
}

@available(*, deprecated, message: "Use FitpaySDKConfiguration sdkVersion")
public let FitpaySDKVersion = "0.5.1"
