import ObjectMapper

public enum APDUPackageResponseState : String {
    case PROCESSED = "PROCESSED"
    case FAILED = "FAILED"
    case ERROR = "ERROR"
    case EXPIRED = "EXPIRED"
}

public class ApduPackage : NSObject, Mappable
{
    internal var links:[ResourceLink]?
    public var seIdType:String?
    public var targetDeviceType:String?
    public var targetDeviceId:String?
    public var packageId:String?
    public var seId:String?
    public var targetAid:String?
    public var apduCommands:[APDUCommand]?
    
    public var state:APDUPackageResponseState?
    public var executedEpoch:NSTimeInterval?
    public var executedDuration:Int?
    
    public var validUntil:String?
    public var validUntilEpoch:NSTimeInterval?
    public var apduPackageUrl:String?
    
    override init() {
        super.init()
    }
    
    public required init?(_ map: Map)
    {
    }
    
    public func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        seIdType <- map["seIdType"]
        targetDeviceType <- map["targetDeviceType"]
        targetDeviceId <- map["targetDeviceId"]
        packageId <- map["packageId"]
        seId <- map["seId"]
        apduCommands <- map["commandApdus"]
        validUntil <- map["validUntil"]
        validUntilEpoch <- (map["validUntilEpoch"], NSTimeIntervalTransform())
        apduPackageUrl <- map["apduPackageUrl"]
    }
    
    public var isExpired : Bool {
//        return validUntilEpoch <= CLong(NSDate().timeIntervalSince1970)
        // validUntilEpoch not currently in the commit event

        return false
    }
    
    public var responseDictionary : [String:AnyObject] {
        get {
            var dic : [String:AnyObject] = [:]
            
            if let packageId = self.packageId {
                dic["packageId"] = packageId
            }
            
            if let state = self.state {
                dic["state"] = state.rawValue
            }
            
            if let executed = self.executedEpoch {
                dic["executedTsEpoch"] = Int(executed)
            }
            
            if state == APDUPackageResponseState.EXPIRED {
                return dic
            }
            
            if let executedDuration = self.executedDuration {
                dic["executedDuration"] = executedDuration
            }
            
            if let apduResponses = self.apduCommands {
                if apduResponses.count > 0 {
                    var responsesArray : [AnyObject] = []
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

public enum APDUResponseType : Int {
    case Success = 0x0
    case Warning
    case Error
}

public class APDUCommand : NSObject, Mappable {

    internal var links:[ResourceLink]?
    public var commandId:String?
    public var groupId:Int = 0
    public var sequence:Int = 0
    public var command:String?
    public var type:String?
    
    public var responseCode:String?
    public var responseData:String?
    
    public var responseType : APDUResponseType? {
        guard let responseCode = self.responseCode, responseCodeDataType = responseCode.hexToData() else {
            return nil
        }
        
        let responseArray = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(responseCodeDataType.bytes), count: responseCodeDataType.length))
        
        for successCode in APDUCommand.successResponses {
            if responseArray[0] != successCode[0] {
                continue
            }
            
            if successCode.count == 1 {
                return APDUResponseType.Success
            }
            
            if responseArray.count > 1 && successCode.count > 1 {
                if responseArray[1] == successCode[1] {
                    return APDUResponseType.Success
                }
            }
        }
        
        for warningCode in APDUCommand.warningResponses {
            if responseArray[0] != warningCode[0] {
                continue
            }
            
            if warningCode.count == 1 {
                return APDUResponseType.Warning
            }
            
            if responseArray.count > 1 && warningCode.count > 1 {
                if responseArray[1] == warningCode[1] {
                    return APDUResponseType.Warning
                }
            }
        }
        
        return APDUResponseType.Error
    }
    
    override init() {
        super.init()
    }
    
    public required init?(_ map: Map)
    {
        
    }
    
    public func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        commandId <- map["commandId"]
        groupId <- map["groupId"]
        sequence <- map["sequence"]
        command <- map["command"]
        type <- map["type"]
    }
    
    public var responseDictionary : [String:AnyObject] {
        get {
            var dic : [String:AnyObject] = [:]
            
            if let commandId = self.commandId {
                dic["commandId"] = commandId
            }
            
            if let responseCode = self.responseCode {
                dic["responseCode"] = responseCode
            }
            
            if let responseData = self.responseData {
                dic["responseData"] = responseData
            }
            
            return dic
        }
    }
    
    
    internal static let successResponses : [[UInt8]] = [
        [0x90, 0x00],
        [0x61/*, XX */]
    ]
    
    internal static let warningResponses : [[UInt8]] = [
        [0x62/*, XX */],
        [0x63/*, XX */],
        [0, 1] //TODO: delete this
    ]
}
