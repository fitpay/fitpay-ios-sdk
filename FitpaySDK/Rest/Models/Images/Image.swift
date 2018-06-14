import Foundation

open class Image: NSObject, ClientModel, Serializable, AssetRetrivable {
    open var mimeType: String?
    open var height: Int?
    open var width: Int?
    
    var client: RestClientInterface?
    
    var links: [ResourceLink]?
    
    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case mimeType
        case height
        case width
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        mimeType = try? container.decode(.mimeType)
        height = try? container.decode(.height)
        width = try? container.decode(.width)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(mimeType, forKey: .mimeType)
        try? container.encode(height, forKey: .height)
        try? container.encode(width, forKey: .width)
    }
    
    open func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler) {
        let resource = Image.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.assets(url, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: Image.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
    
}
