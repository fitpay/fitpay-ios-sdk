import ObjectMapper

public class RtmConfig: NSObject, Mappable {
    public var clientId: String?
    public var redirectUri: String?
    public var userEmail: String?
    public var deviceInfo: DeviceInfo?
    
    public init(clientId:String, redirectUri:String, userEmail:String?, deviceInfo:DeviceInfo?) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.userEmail = userEmail
        self.deviceInfo = deviceInfo
    }
    
    public required init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        clientId <- map["clientId"]
        redirectUri <- map["redirectUri"]
        userEmail <- map["userEmail"]
        deviceInfo <- map["paymentDevice"]
    }

}