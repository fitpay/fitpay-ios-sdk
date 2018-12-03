import Foundation

public class CountryCollection: ClientModel, Serializable {
    
    public var countries: [String: Country]
    
    public var countryList: [Country] {
        return Array(countries.values)
    }
    
    weak var client: RestClient? {
        didSet {
            countries.values.forEach { $0.client = client }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case countries
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        countries = try container.decode(.countries)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encodeIfPresent(countries, forKey: .countries)
    }
    
}
