@objcMembers open class EncryptionKey: NSObject, Serializable {

    open var keyId: String?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var expiration: String?
    open var expirationEpoch: TimeInterval?
    open var serverPublicKey: String?
    open var clientPublicKey: String?
    open var active: Bool?
    
    var links: [ResourceLink]?

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case keyId
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case expiration = "expirationTs"
        case expirationEpoch = "expirationTsEpoch"
        case serverPublicKey
        case clientPublicKey
        case active
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        keyId = try? container.decode(.keyId)
        created = try? container.decode(.created)
        createdEpoch = try container.decode(.createdEpoch, transformer: NSTimeIntervalTypeTransform())
        expiration = try? container.decode(.expiration)
        expirationEpoch = try container.decode(.expirationEpoch, transformer: NSTimeIntervalTypeTransform())
        serverPublicKey = try? container.decode(.serverPublicKey)
        clientPublicKey = try? container.decode(.clientPublicKey)
        active = try? container.decode(.active)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(keyId, forKey: .keyId)
        try? container.encode(created, forKey: .created)
        try? container.encode(createdEpoch, forKey: .createdEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(expiration, forKey: .expiration)
        try? container.encode(expirationEpoch, forKey: .expirationEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(serverPublicKey, forKey: .serverPublicKey)
        try? container.encode(clientPublicKey, forKey: .clientPublicKey)
        try? container.encode(active, forKey: .active)
    }

    /**
     Validates encryption key expiration date
     */
    func isExpired() -> Bool {
        let currentEpoch = Date().timeIntervalSince1970
        guard let expirationEpoch = self.expirationEpoch else { return false }
        let platoformRequestTimeout: Double = 60
        let isExpired = expirationEpoch - platoformRequestTimeout < currentEpoch
        return isExpired
    }
}
