import Foundation

/// Main Configuration Object
///
/// Set variables before instantiating other Fitpay objects
@objc public class FitpayConfig: NSObject {
    
    /// Implicit allows you to get a single user token
    @objc public static var clientId: String!
    
    /// Used for web calls
    @objc public static var webURL = "https://webapp.fit-pay.com"
    
    /// Used for redirects
    @objc public static var redirectURL = "https://webapp.fit-pay.com"
    
    /// Used for API calls
    @objc public static var apiURL = "https://api.fit-pay.com"
    
    /// Used during login
    @objc public static var authURL = "https://auth.fit-pay.com"
    
    /// Turn on when you are ready to implement App 2 App stepup methods
    @objc public static var supportApp2App = false
    
    /// Logs will be sent for every level equal or above what is set
    @objc public static var minLogLevel: LogLevel = LogLevel.info
    
    /// SDK Version using semantic versioning MAJOR.MINOR.PATCH
    @objc public static let sdkVersion = Bundle(for: FitpayConfig.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    //MARK: - Functions
    
    /**
     Setup FitpaySDK quick method
     
     Uses all of the default variables and sets clientId
     
     Call configure in the AppDelegate `didFinishLaunchingWithOptions:` before doing anything else with the FItpaySDK
     
     - Parameter clientId: clientId from Fitpay
     */
    @objc public static func configure(clientId: String) {
        self.clientId = clientId
        
        finishConfigure()
    }
    
    /// Setup FitpaySDK advanced method
    ///
    /// All variables are customizable via json file
    ///
    /// Call configure in the AppDelegate `didFinishLaunchingWithOptions:`  before doing anything else with the FItpaySDK
    ///
    /// - Parameters:
    ///   - fileName: name without extension or leading path defaults to `fitpayconfig`
    ///   - bundle: bundle the json is in, defaults to main. Used primarily for testing.
    @objc public static func configure(fileName: String = "fitpayconfig", bundle: Bundle = Bundle.main) {
        guard let path = bundle.path(forResource: fileName, ofType: "json") else { return }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else { return }
        guard let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) else { return }
        guard let fitpayConfigModel = try? FitpayConfigModel(jsonResult) else { return }
        
        FitpayConfig.clientId = fitpayConfigModel.clientId
        
        FitpayConfig.webURL = fitpayConfigModel.webURL ?? FitpayConfig.webURL
        FitpayConfig.redirectURL = fitpayConfigModel.redirectURL ?? FitpayConfig.redirectURL
        FitpayConfig.apiURL = fitpayConfigModel.apiURL ?? FitpayConfig.apiURL
        FitpayConfig.authURL = fitpayConfigModel.authURL ?? FitpayConfig.authURL
        
        FitpayConfig.supportApp2App = fitpayConfigModel.supportApp2App ?? FitpayConfig.supportApp2App
        FitpayConfig.minLogLevel = LogLevel(rawValue: fitpayConfigModel.minLogLevel ?? FitpayConfig.minLogLevel.rawValue) ?? LogLevel.info
        
        if let configModelWeb = fitpayConfigModel.web {
            FitpayConfig.Web.demoMode = configModelWeb.demoMode ?? FitpayConfig.Web.demoMode
            FitpayConfig.Web.demoCardGroup = configModelWeb.demoCardGroup
            FitpayConfig.Web.cssURL = configModelWeb.cssURL
            FitpayConfig.Web.baseLanguageURL = configModelWeb.baseLanguageURL
            FitpayConfig.Web.supportCardScanner = configModelWeb.supportCardScanner ?? FitpayConfig.Web.supportCardScanner
            FitpayConfig.Web.automaticallySubscribeToUserEventStream = configModelWeb.automaticallySubscribeToUserEventStream ?? FitpayConfig.Web.automaticallySubscribeToUserEventStream
            FitpayConfig.Web.automaticallySyncFromUserEventStream = configModelWeb.automaticallySyncFromUserEventStream ?? FitpayConfig.Web.automaticallySyncFromUserEventStream
        }
        
       finishConfigure()
    }
    
    // MARK: - Private
    
    private static func finishConfigure() {
        loadEnvironmentVariables()
        
        log.addOutput(output: ConsoleOutput())
        log.debug("CONFIG: Fitpay configured from file successfully")
    }
    
    private static func loadEnvironmentVariables() {
        let envDict = ProcessInfo.processInfo.environment
        
        if let clientId = envDict["SDK_CLIENT_ID"], !clientId.isEmpty {
            FitpayConfig.clientId = clientId
        }
        
        if let baseAPIUrl = envDict["SDK_API_BASE_URL"], !baseAPIUrl.isEmpty {
            FitpayConfig.apiURL = baseAPIUrl
        }
        
        if let baseAuthUrl = envDict["SDK_AUTHORIZE_BASE_URL"], !baseAuthUrl.isEmpty {
            FitpayConfig.authURL = baseAuthUrl
        }
        
    }
    
}

// MARK: - WebConfig

@objc extension FitpayConfig {
    
    /// Configuration options related to the Web specifically
    @objc public class Web: NSObject {
        
        /// Shows autofill options on the add card page when enabled
        @objc public static var demoMode = false
        
        /// Changes autofill options to include a default and auto-verify version of one card type
        @objc public static var demoCardGroup: String?
        
        /// Overrides the default CSS
        @objc public static var cssURL: String?
        
        /**
         [Getting Started with Translations]: https://support.fit-pay.com/hc/en-us/articles/115003060672-Getting-Started-with-Translations
         
         Base URL to language files used in conjuction with language parameter in RTM
         
         More info at [Getting Started with Translations]
         */
        @objc public static var baseLanguageURL: String?
        
        /// Turn on when you are ready to implement card scanning methods
        @objc public static var supportCardScanner = false
        
        /// Turn off SSE connection to reduce overhead if not in use
        @objc public static var automaticallySubscribeToUserEventStream = true
        
        /// Trigger syncs from an SSE connection automatically established
        ///
        /// `automaticallySubscribeToUserEventStream` must also be on to sync
        @objc public static var automaticallySyncFromUserEventStream = true

    }
    
}

// MARK: - Nested Structs for json

extension FitpayConfig {
    
    private struct FitpayConfigModel: Serializable {
        var clientId: String
        var webURL: String?
        var redirectURL: String?
        var apiURL: String?
        var authURL: String?
        var supportApp2App: Bool?
        var minLogLevel: Int?
        var web: FitpayConfigWebModel?
    }
    
    private struct FitpayConfigWebModel: Serializable  {
        var demoMode: Bool?
        var demoCardGroup: String?
        var cssURL: String?
        var baseLanguageURL: String?
        var supportCardScanner: Bool?
        var automaticallySubscribeToUserEventStream: Bool?
        var automaticallySyncFromUserEventStream: Bool?
    }
    
}
