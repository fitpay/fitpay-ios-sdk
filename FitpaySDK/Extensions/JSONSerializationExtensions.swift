import Foundation

extension JSONSerialization {
    
    class func JSONString(_ object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
            let string = String(data: data, encoding: String.Encoding.utf8) else {
                return nil
        }
        
        return string
    }
    
}
