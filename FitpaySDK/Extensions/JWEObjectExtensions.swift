import JWTDecode

extension JWEObject {
    
    class func decrypt<T>(_ encryptedData: String?, expectedKeyId: String?, secret: Data) -> T? where T: Serializable {
        guard let encryptedData = encryptedData else { return nil }
        
        let jweResult = JWEObject(payload: encryptedData)
        
        if let expectedKeyId = expectedKeyId {
            guard jweResult.header?.kid == expectedKeyId else { return nil }
        }
        
        if let decryptResult = try? jweResult.decrypt(secret) {
            return try? T(decryptResult)
        }
        
        return nil
    }
    
    class func decryptSigned(_ encryptedData: String?, expectedKeyId: String?, secret: Data) -> String? {
        guard let encryptedData = encryptedData else { return nil }
        
        let jweResult = JWEObject(payload: encryptedData)
        
        if let expectedKeyId = expectedKeyId {
            guard jweResult.header?.kid == expectedKeyId else { return nil }
        }
        
        guard let decryptResult = try? jweResult.decrypt(secret) else { return nil }
        guard jweResult.header?.cty == "JWT" else { return nil }
                
        let claimSet = try? decode(jwt: decryptResult!)
        
        let payload = claimSet?.claim(name: "data").string
        
        return payload
    }
    
}
