import Foundation

public class ProvinceCollection: Serializable {
    
    public var name: String?
    public var iso: String?
    
    public var provinces: [String: Province]
    
    public var provinceList: [Province] {
        return Array(provinces.values)
    }
    
}
