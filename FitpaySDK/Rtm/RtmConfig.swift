import ObjectMapper

open class RtmConfig: NSObject, Mappable {
    open var clientId: String?
    open var redirectUri: String?
    open var userEmail: String?
    open var deviceInfo: DeviceInfo?
    open var hasAccount: Bool?
    open var version: String?
    open var demoMode: Bool?
    open var customCSSUrl: String?
    open var demoCardGroup: String?
    
    public init(clientId:String = FitpaySDKConfiguration.defaultConfiguration.clientId, redirectUri:String = FitpaySDKConfiguration.defaultConfiguration.redirectUri, userEmail:String?, deviceInfo:DeviceInfo?, hasAccount:Bool = false) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.userEmail = userEmail
        self.deviceInfo = deviceInfo
        self.hasAccount = hasAccount
    }
    
    public required init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        clientId <- map["clientId"]
        redirectUri <- map["redirectUri"]
        userEmail <- map["userEmail"]
        deviceInfo <- map["paymentDevice"]
        hasAccount <- map["account"]
        version <- map["version"]
        demoMode <- map["demoMode"]
        customCSSUrl <- map["themeOverrideCssUrl"]
        demoCardGroup <- map["demoCardGroup"]
    }
}
