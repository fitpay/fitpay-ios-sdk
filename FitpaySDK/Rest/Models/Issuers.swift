import Foundation

open class Issuers: Serializable, ClientModel {
    
    public var countries: [String: Country]?

    var links: [ResourceLink]?
    
    weak var client: RestClientInterface?

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case countries 
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        countries = try? container.decode(.countries)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(countries, forKey: .countries)
    }
    
    public struct Country: Serializable {
        public var cardNetworks: [String: CardNetwork]?
    }
    
    public struct CardNetwork: Serializable {
        public var issuers: [String]?
    }
}
