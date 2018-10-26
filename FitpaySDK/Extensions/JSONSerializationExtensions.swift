import Foundation

extension JSONSerialization {
    
    class func JSONString(_ object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
}
