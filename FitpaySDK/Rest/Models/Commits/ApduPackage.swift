import Foundation

/// A set of APDUCommands and associated data inside of some Commits
@objcMembers open class ApduPackage: NSObject, Serializable {

    open var seIdType: String?
    open var targetDeviceType: String?
    open var targetDeviceId: String?
    open var packageId: String?
    open var seId: String?
    open var targetAid: String?
    open var apduCommands: [APDUCommand]?

    open var state: APDUPackageResponseState?
    open var executedEpoch: TimeInterval?
    open var executedDuration: Int?

    open var validUntil: String?
    open var validUntilEpoch: Date?
    open var apduPackageUrl: String?
    
    var links: [ResourceLink]?
    
    @objc open static var APDUPackageResponseStateProcessed: String {
        return APDUPackageResponseState.processed.rawValue
    }
    
    @objc open static var APDUPackageResponseStateFailed: String {
        return APDUPackageResponseState.failed.rawValue
    }
    
    @objc open static var APDUPackageResponseStateError: String {
        return APDUPackageResponseState.error.rawValue
    }
    
    @objc open static var APDUPackageResponseStateExpired: String {
        return APDUPackageResponseState.expired.rawValue
    }
    
    @objc open static var APDUPackageResponseStateNotProcessed: String {
        return APDUPackageResponseState.notProcessed.rawValue
    }

    //Date format for date transformation
    private let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case seIdType
        case targetDeviceType
        case targetDeviceId
        case packageId
        case seId
        case apduCommands = "commandApdus"
        case state
        case validUntil
        case apduPackageUrl
    }
    
    override init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        seIdType = try? container.decode(.seIdType)
        targetDeviceType = try? container.decode(.targetDeviceType)
        targetDeviceId = try? container.decode(.targetDeviceId)
        packageId = try? container.decode(.packageId)
        seId = try? container.decode(.seId)
        apduCommands = try? container.decode(.apduCommands)
        state = try? container.decode(.state)
        validUntil = try? container.decode(.validUntil)
        validUntilEpoch = try container.decode(.validUntil, transformer: CustomDateFormatTransform(formatString: dateFormat))
        apduPackageUrl = try? container.decode(.apduPackageUrl)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(seIdType, forKey: .seIdType)
        try? container.encode(targetDeviceType, forKey: .targetDeviceType)
        try? container.encode(targetDeviceId, forKey: .targetDeviceId)
        try? container.encode(packageId, forKey: .packageId)
        try? container.encode(seId, forKey: .seId)
        try? container.encode(apduCommands, forKey: .apduCommands)
        try? container.encode(state, forKey: .state)
        try? container.encode(validUntil, forKey: .validUntil)
        try? container.encode(apduPackageUrl, forKey: .apduPackageUrl)
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

