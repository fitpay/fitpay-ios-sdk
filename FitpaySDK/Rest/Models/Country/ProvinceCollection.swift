import Foundation

public class ProvinceCollection: Serializable {
    
    public var name: String?
    public var iso: String?
    
    public var provinces: [String: Province]
    
    public var provinceList: [Province] {
        return Array(provinces.values)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case iso
        case provinces
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try? container.decode(.name)
        iso = try? container.decode(.iso)
        provinces = try container.decode(.provinces)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(name, forKey: .name)
        try? container.encode(iso, forKey: .iso)
        try? container.encodeIfPresent(provinces, forKey: .provinces)
    }
    
    // MARK: - Public Functions
    
    public func getProvinces() -> [Province] {
        return Array(provinces.values)
    }
    
}
