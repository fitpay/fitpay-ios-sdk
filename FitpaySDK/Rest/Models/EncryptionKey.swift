
import ObjectMapper

@objcMembers
open class EncryptionKey: NSObject, Mappable
{
    internal var links: [ResourceLink]?
    open var keyId: String?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var expiration: String?
    open var expirationEpoch: TimeInterval?
    open var serverPublicKey: String?
    open var clientPublicKey: String?
    open var active: Bool?

    public required init?(map: Map)
    {

    }

    open func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        keyId <- map["keyId"]
        created <- map["createdTs"]
        createdEpoch <- (map["createdTsEpoch"], NSTimeIntervalTransform())
        expiration <- map["expirationTs"]
        expirationEpoch <- (map["expirationTsEpoch"], NSTimeIntervalTransform())
        serverPublicKey <- map["serverPublicKey"]
        clientPublicKey <- map["clientPublicKey"]
        active <- map["active"]
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
