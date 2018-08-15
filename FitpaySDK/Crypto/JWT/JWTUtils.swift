import Foundation

class JWTUtils {
    
    static func decodeJWTPart(_ value: String) throws -> [String: Any] {
        guard let bodyData = value.base64URLdecoded() else {
            throw JWTError.invalidBase64Url
        }
                
        guard let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
            throw JWTError.invalidJSON
        }
        
        return payload
    }
    
}
