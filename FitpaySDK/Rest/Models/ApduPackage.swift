import ObjectMapper

public enum APDUPackageResponseState : String {
    case processed    = "PROCESSED"
    case failed       = "FAILED"
    case error        = "ERROR"
    case expired      = "EXPIRED"
    case notProcessed = "NOT_PROCESSED"
}

open class ApduPackage : NSObject, Mappable
{
    internal var links: [ResourceLink]?
    open var seIdType: String?
    open var targetDeviceType: String?
    open var targetDeviceId: String?
    open var packageId: String?
    open var seId: String?
    open var targetAid: String?
    open var apduCommands: [APDUCommand]?

    open var state: APDUPackageResponseState?
    open var executedEpoch: TimeInterval?
    open var executedDuration: Int64?

    open var validUntil: String?
    open var validUntilEpoch: Date?
    open var apduPackageUrl: String?
    
    @objc open static var APDUPackageResponseStateProcessed: String
    {
        return APDUPackageResponseState.processed.rawValue
    }
    @objc open static var APDUPackageResponseStateFailed: String
    {
        return APDUPackageResponseState.failed.rawValue
    }
    @objc open static var APDUPackageResponseStateError: String
    {
        return APDUPackageResponseState.error.rawValue
    }
    @objc open static var APDUPackageResponseStateExpired: String
    {
        return APDUPackageResponseState.expired.rawValue
    }
    @objc open static var APDUPackageResponseStateNotProcessed: String
    {
        return APDUPackageResponseState.notProcessed.rawValue
    }

    override init() {
        super.init()
    }
    
    public required init?(map: Map)
    {
    }
    
    open func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        seIdType <- map["seIdType"]
        targetDeviceType <- map["targetDeviceType"]
        targetDeviceId <- map["targetDeviceId"]
        packageId <- map["packageId"]
        seId <- map["seId"]
        apduCommands <- map["commandApdus"]
        validUntil <- map["validUntil"]
        validUntilEpoch <- (map["validUntil"], CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSX"))
        apduPackageUrl <- map["apduPackageUrl"]
    }

    open var isExpired: Bool {
        guard let validUntilEpoch = self.validUntilEpoch else {
            return false
        }
        
        return validUntilEpoch <= Date()
    }

    open var responseDictionary: [String: Any] {
        get {
            var dic: [String: Any] = [:]

            if let packageId = self.packageId {
                dic["packageId"] = packageId
            }

            if let state = self.state {
                dic["state"] = state.rawValue
            }

            if let executed = self.executedEpoch {
                dic["executedTsEpoch"] = Int64(executed * 1000)
            }

            if let executedDuration = self.executedDuration {
                dic["executedDuration"] = executedDuration
            }

            if state == APDUPackageResponseState.expired {
                dic["apduResponses"] = []
                return dic
            }

            if let apduResponses = self.apduCommands {
                if apduResponses.count > 0 {
                    var responsesArray: [Any] = []
                    for resp in apduResponses {
                        if let _ = resp.responseData {
                            responsesArray.append(resp.responseDictionary)
                        }
                    }

                    dic["apduResponses"] = responsesArray
                }
            }

            return dic
        }
    }

}

