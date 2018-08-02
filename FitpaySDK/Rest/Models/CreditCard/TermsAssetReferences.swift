import Foundation

open class TermsAssetReferences: NSObject, ClientModel, Serializable, AssetRetrivable {
    open var mimeType: String?
    
    var client: RestClient?
    var links: [ResourceLink]?
    
    private static let selfResourceKey = "self"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case mimeType
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        mimeType = try? container.decode(.mimeType)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(mimeType, forKey: .mimeType)
    }
    
    @objc open func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler) {
        let resource = TermsAssetReferences.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.assets(url, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: TermsAssetReferences.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
}
