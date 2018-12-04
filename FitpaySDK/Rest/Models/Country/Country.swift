import Foundation

public class Country: ClientModel, Serializable {
    
    public var name: String?
    public var iso: String?
    
    public var provincesAvailable: Bool {
        return links?[Country.provincesResourceKey] != nil
    }
    
    var links: [String: Link]?
    
    weak var client: RestClient?
    
    private static let provincesResourceKey = "provinces"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case name
        case iso
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try? container.decode(.links)
        name = try? container.decode(.name)
        iso = try? container.decode(.iso)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encodeIfPresent(links, forKey: .links)
        try? container.encode(name, forKey: .name)
        try? container.encode(iso, forKey: .iso)
    }
    
    // MARK: - Public Functions
    
    open func getProvinces(_ completion: @escaping (_ countries: ProvinceCollection?, _ error: ErrorResponse?) -> Void) {
        let resource = Country.provincesResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }
    
    // MARK: - Private Functions
    
    private func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: Country.self, client: client, url: links?[resource]?.href, resource: resource)
    }
    
}
