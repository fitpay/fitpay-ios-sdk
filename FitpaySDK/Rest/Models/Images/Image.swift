import Foundation

open class Image: NSObject, ClientModel, Serializable, AssetRetrivable {
    
    open var mimeType: String?
    open var height: Int?
    open var width: Int?
    
    open var links: [ResourceLink]?
    
    weak var client: RestClient?
    
    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case mimeType
        case height
        case width
    }
    
    // MARK: - Lifecycle

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
    
    // MARK: - Public Functions
    
    open func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler) {
        let resource = Image.selfResourceKey
        
        guard let url = links?.url(resource), let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.assets(url, completion: completion)
    }
    
    // MARK: - Private Functions
    
    private func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: VerificationMethod.self, client: client, url: links?.url(resource), resource: resource)
    }
    
}
