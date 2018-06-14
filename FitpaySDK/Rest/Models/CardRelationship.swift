import Foundation

open class CardRelationship: NSObject, ClientModel, Serializable, SecretApplyable {
    open var creditCardId: String?
    open var pan: String?
    open var expMonth: Int?
    open var expYear: Int?
    
    weak var client: RestClientInterface?
    
    var links: [ResourceLink]?
    var encryptedData: String?
    
    private static let selfResourceKey = "self"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case creditCardId
        case encryptedData
        case pan
        case expMonth
        case expYear
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        creditCardId = try? container.decode(.creditCardId)
        encryptedData = try? container.decode(.encryptedData)
        pan = try? container.decode(.pan)
        expMonth = try? container.decode(.expMonth)
        expYear = try? container.decode(.expYear)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(creditCardId, forKey: .creditCardId)
        try? container.encode(encryptedData, forKey: .encryptedData)
        try? container.encode(pan, forKey: .pan)
        try? container.encode(expMonth, forKey: .expMonth)
        try? container.encode(expYear, forKey: .expYear)
    }
    
    func applySecret(_ secret: Data, expectedKeyId: String?) {
        if let decryptedObj: CardRelationship = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret) {
            self.pan = decryptedObj.pan
            self.expMonth = decryptedObj.expMonth
            self.expYear = decryptedObj.expYear
        }
    }
    
    /**
     Get a single relationship
     
     - parameter completion:   RelationshipHandler closure
     */
    @objc open func relationship(_ completion: @escaping RestClient.RelationshipHandler) {
        let resource = CardRelationship.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.relationship(url, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CardRelationship.self, client: client, url: url, resource: resource))
        }
    }
    
}
