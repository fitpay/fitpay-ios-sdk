protocol RtmConfigProtocol {
    var redirectUri: String? { get }
    var deviceInfo: Device? { get set }
    var accessToken: String? { get set }
    var hasAccount: Bool { get }

    func jsonDict() -> [String: Any]
}

class RtmConfig: NSObject, Serializable, RtmConfigProtocol {
    var redirectUri: String?
    var deviceInfo: Device?
    var hasAccount: Bool = false
    var accessToken: String?
    
    var language: String?
    
    private var clientId: String?
    private var userEmail: String?
    private var version: String?
    private var demoMode = false
    private var customCSSUrl: String?
    private var demoCardGroup: String?
    private var baseLanguageUrl: String?
    private var useWebCardScanner = true
    
    private var customs: [String: Any] = [:]
    
    init(userEmail: String?, deviceInfo: Device?, hasAccount: Bool = false) {
        super.init()

        self.clientId = FitpayConfig.clientId
        self.redirectUri = FitpayConfig.redirectURL
        self.demoMode = FitpayConfig.Web.demoMode
        self.demoCardGroup = FitpayConfig.Web.demoCardGroup
        self.customCSSUrl = FitpayConfig.Web.cssURL
        self.useWebCardScanner = !FitpayConfig.Web.supportCardScanner
        self.baseLanguageUrl = FitpayConfig.Web.baseLanguageURL
        
        self.userEmail = userEmail
        self.deviceInfo = deviceInfo
        self.hasAccount = hasAccount
    }

    private enum CodingKeys: String, CodingKey {
        case clientId
        case redirectUri
        case userEmail
        case deviceInfo = "paymentDevice"
        case hasAccount = "account"
        case version
        case demoMode
        case customCSSUrl = "themeOverrideCssUrl"
        case demoCardGroup
        case accessToken
        case language
        case baseLanguageUrl = "baseLangUrl"
        case useWebCardScanner 
    }
    
    func jsonDict() -> [String: Any] {
        var dict = self.toJSON()!
        dict += customs
        return dict
    }

}
