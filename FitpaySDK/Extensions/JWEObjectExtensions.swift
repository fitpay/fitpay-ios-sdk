import ObjectMapper
import JWTDecode

extension JWEObject {
    
    class func decrypt<T: Mappable>(_ encryptedData: String?, expectedKeyId: String?, secret: Data) -> T? {
        guard let encryptedData = encryptedData else { return nil }
        
        let jweResult = JWEObject.parse(payload: encryptedData)
        
        if let expectedKeyId = expectedKeyId {
            guard jweResult?.header?.kid == expectedKeyId else { return nil }
        }
        
        if let decryptResult = try? jweResult?.decrypt(secret) {
            return Mapper<T>().map(JSONString: decryptResult!)
        }
        
        return nil
    }
    
    class func decryptSigned(_ encryptedData: String?, expectedKeyId: String?, secret: Data) -> String? {
        guard let encryptedData = encryptedData else { return nil }
        
        let jweResult = JWEObject.parse(payload: encryptedData)
        
        if let expectedKeyId = expectedKeyId {
            guard jweResult?.header?.kid == expectedKeyId else { return nil }
        }
        
        guard let decryptResult = try? jweResult?.decrypt(secret) else { return nil }
        guard jweResult?.header?.cty == "JWT" else { return nil }
                
        let claimSet = try? decode(jwt: decryptResult!)
        
        let payload = claimSet?.claim(name: "data").string
        
        return payload

    }
    
}
