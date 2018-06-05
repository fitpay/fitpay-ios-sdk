open class APDUCommand: NSObject, Serializable, APDUResponseProtocol {
    
    var links: [ResourceLink]?
    open var commandId: String?
    open var groupId: Int = 0
    open var sequence: Int = 0
    open var command: String?
    open var type: String?
    open var continueOnFailure: Bool = false
    
    open var responseData: Data?
    
    override init() {
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case commandId
        case groupId
        case sequence
        case command
        case type
        case continueOnFailure 
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        commandId = try? container.decode(.commandId)
        groupId = try container.decodeIfPresent(Int.self, forKey: .groupId) ?? 0
        sequence = try container.decodeIfPresent(Int.self, forKey: .sequence) ?? 0
        command = try? container.decode(.command)
        type = try? container.decode(.type)
        continueOnFailure = try container.decodeIfPresent(Bool.self, forKey: .continueOnFailure) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(commandId, forKey: .commandId)
        try? container.encode(groupId, forKey: .groupId)
        try? container.encode(sequence, forKey: .sequence)
        try? container.encode(command, forKey: .command)
        try? container.encode(type, forKey: .type)
        try? container.encode(continueOnFailure, forKey: .continueOnFailure)
    }

    open var responseDictionary: [String: Any] {
        get {
            var dic: [String: Any] = [:]
            
            if let commandId = self.commandId {
                dic["commandId"] = commandId
            }
            
            if let responseCode = self.responseCode {
                dic["responseCode"] = responseCode.hex
            }
            
            if let responseData = self.responseData {
                dic["responseData"] = responseData.hex
            }
            
            return dic
        }
    }
}

