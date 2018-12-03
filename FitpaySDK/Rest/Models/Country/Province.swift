import Foundation

public class Province: Serializable {
    
    public var name: String?
    public var iso: String?
    
    private static let provincesResourceKey = "provinces"
    
    private enum CodingKeys: String, CodingKey {
        case name
        case iso
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try? container.decode(.name)
        iso = try? container.decode(.iso)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(name, forKey: .name)
        try? container.encode(iso, forKey: .iso)
    }

}
