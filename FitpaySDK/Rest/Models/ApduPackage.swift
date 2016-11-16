import ObjectMapper

public enum APDUPackageResponseState : String {
    case PROCESSED = "PROCESSED"
    case FAILED = "FAILED"
    case ERROR = "ERROR"
    case EXPIRED = "EXPIRED"
}

open class ApduPackage : NSObject, Mappable
{
    internal var links:[ResourceLink]?
    open var seIdType:String?
    open var targetDeviceType:String?
    open var targetDeviceId:String?
    open var packageId:String?
    open var seId:String?
    open var targetAid:String?
    open var apduCommands:[APDUCommand]?
    
    open var state:APDUPackageResponseState?
    open var executedEpoch:TimeInterval?
    open var executedDuration:Int?
    
    open var validUntil:String?
    open var validUntilEpoch:TimeInterval?
    open var apduPackageUrl:String?
    
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
        validUntilEpoch <- (map["validUntilEpoch"], NSTimeIntervalTransform())
        apduPackageUrl <- map["apduPackageUrl"]
    }
    
    open var isExpired : Bool {
//        return validUntilEpoch <= CLong(NSDate().timeIntervalSince1970)
        // validUntilEpoch not currently in the commit event

        return false
    }
    
    open var responseDictionary : [String:AnyObject] {
        get {
            var dic : [String:AnyObject] = [:]
            
            if let packageId = self.packageId {
                dic["packageId"] = packageId as AnyObject?
            }
            
            if let state = self.state {
                dic["state"] = state.rawValue as AnyObject?
            }
            
            if let executed = self.executedEpoch {
                dic["executedTsEpoch"] = Int(executed) as AnyObject?
            }
            
            if state == APDUPackageResponseState.EXPIRED {
                return dic
            }
            
            if let executedDuration = self.executedDuration {
                dic["executedDuration"] = executedDuration as AnyObject?
            }
            
            if let apduResponses = self.apduCommands {
                if apduResponses.count > 0 {
                    var responsesArray : [AnyObject] = []
                    for resp in apduResponses {
                        if let _ = resp.responseData {
                            responsesArray.append(resp.responseDictionary as AnyObject)
                        }
                    }
                    
                    dic["apduResponses"] = responsesArray as AnyObject?
                }
            }
            
            return dic
        }
    }
    
}

public enum APDUResponseType : Int {
    case success = 0x0
    case warning
    case error
}

open class APDUCommand : NSObject, Mappable {

    internal var links:[ResourceLink]?
    open var commandId:String?
    open var groupId:Int = 0
    open var sequence:Int = 0
    open var command:String?
    open var type:String?
    open var continueOnFailure:Bool?
    
    open var responseCode:String?
    open var responseData:String?
    
    open var responseType : APDUResponseType? {
        guard let responseCode = self.responseCode, let responseCodeDataType = responseCode.hexToData() else {
            return nil
        }
        
        let responseArray = Array(UnsafeBufferPointer(start: (responseCodeDataType as NSData).bytes.bindMemory(to: UInt8.self, capacity: responseCodeDataType.count), count: responseCodeDataType.count))
        
        for successCode in APDUCommand.successResponses {
            if responseArray[0] != successCode[0] {
                continue
            }
            
            if successCode.count == 1 {
                return APDUResponseType.success
            }
            
            if responseArray.count > 1 && successCode.count > 1 {
                if responseArray[1] == successCode[1] {
                    return APDUResponseType.success
                }
            }
        }
        
        for warningCode in APDUCommand.warningResponses {
            if responseArray[0] != warningCode[0] {
                continue
            }
            
            if warningCode.count == 1 {
                return APDUResponseType.warning
            }
            
            if responseArray.count > 1 && warningCode.count > 1 {
                if responseArray[1] == warningCode[1] {
                    return APDUResponseType.warning
                }
            }
        }
        
        return APDUResponseType.error
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
        commandId <- map["commandId"]
        groupId <- map["groupId"]
        sequence <- map["sequence"]
        command <- map["command"]
        type <- map["type"]
        continueOnFailure <- map["continueOnFailure"]
    }
    
    open var responseDictionary : [String:AnyObject] {
        get {
            var dic : [String:AnyObject] = [:]
            
            if let commandId = self.commandId {
                dic["commandId"] = commandId as AnyObject?
            }
            
            if let responseCode = self.responseCode {
                dic["responseCode"] = responseCode as AnyObject?
            }
            
            if let responseData = self.responseData {
                dic["responseData"] = responseData as AnyObject?
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
