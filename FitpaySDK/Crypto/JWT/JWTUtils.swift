import Foundation

class JWTUtils {
    static var JWSAlgorithmA256GCMKW = "A256GCMKW"
    static var JWSEncryptionA256GCM = "A256GCM"
    
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
