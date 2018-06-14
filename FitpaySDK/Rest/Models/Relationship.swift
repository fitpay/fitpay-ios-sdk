
@objcMembers
open class Relationship: NSObject, ClientModel, Serializable {
    
    open var device: DeviceInfo?
    
    weak var client: RestClientInterface?
    
    var links: [ResourceLink]?
    var card: CardInfo?
    
    private static let selfResourceKey = "self"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case card
        case device
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        card = try? container.decode(.card)
        device = try? container.decode(.device)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(card, forKey: .card)
        try? container.encode(device, forKey: .device)
    }

    /**
     Removes a relationship between a device and a creditCard if it exists
     
        - parameter completion:   DeleteRelationshipHandler closure
     */
    @objc open func deleteRelationship(_ completion: @escaping RestClient.DeleteHandler) {
        let resource = Relationship.selfResourceKey
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client {
            client.deleteRelationship(url, completion: completion)
        } else {
            completion(ErrorResponse.clientUrlError(domain: Relationship.self, client: client, url: url, resource: resource))
        }
    }
}
