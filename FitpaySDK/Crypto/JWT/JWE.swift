import Foundation

class JWE {
    
    private(set) var encryptedPayload: String?
    private(set) var decryptedPayload: String?
    
    static let AuthenticationTagSize = 16
    static let PayloadIVSize = 16

    private var header: JOSEHeader?
    
    private var cekCt: Data?
    private var iv: Data?
    private var ct: Data?
    private var tag: Data?
    
    private var payloadToEncrypt: String?
    
    private static let CekSize = 32
    private static let CekIVSize = 12
    
    // MARK - Lifecycle
    
    init(_ alg: JWTAlgorithm, enc: JWTEncryption, payload: String, keyId: String?) {
        self.header = JOSEHeader(encryption: enc, algorithm: alg)
        self.header!.kid = keyId
        self.payloadToEncrypt = payload
    }
    
    init(payload: String) {
        self.encryptedPayload = payload
        
        let jwe = payload.components(separatedBy: ".")
        self.header = JOSEHeader(headerPayload: jwe[0])
        self.cekCt = jwe[1].base64URLdecoded()
        self.iv = jwe[2].base64URLdecoded()
        self.ct = jwe[3].base64URLdecoded()
        self.tag = jwe[4].base64URLdecoded()
    }
    
    func encrypt(_ sharedSecret: Data) throws -> String? {
        guard payloadToEncrypt != nil else { return nil }
        
        guard header != nil else {
            throw JWTError.headerNotSpecified
        }
        
        if (header?.alg == .A256GCMKW && header?.enc == .A256GCM) {
            let cek = String.random(JWE.CekSize).data(using: String.Encoding.utf8)
            let cekIV = String.random(JWE.CekIVSize).data(using: String.Encoding.utf8)
            
            let (cekCtCt, cekCTTag) = A256GCMEncryptData(sharedSecret, data: cek!, iv: cekIV!, aad: nil)
            let encodedCekCt = cekCtCt!.base64URLencoded()
            
            let payloadIV = String.random(JWE.PayloadIVSize).data(using: String.Encoding.utf8)
            let encodedPayloadIV = payloadIV?.base64URLencoded()
            
            let encodedHeader: Data!
            let base64UrlHeader: String!
            do {
                header?.tag = cekCTTag
                header?.iv = cekIV
                
                base64UrlHeader = try header?.serialize()
                encodedHeader = base64UrlHeader.data(using: String.Encoding.utf8)
            } catch let error {
                throw error
            }
            
            let (encryptedPayloadCt, encryptedPayloadTag) = A256GCMEncryptData(cek!, data: payloadToEncrypt!.data(using: String.Encoding.utf8)!, iv: payloadIV!, aad: encodedHeader)
            
            let encodedCipherText = encryptedPayloadCt?.base64URLencoded()
            let encodedAuthTag = encryptedPayloadTag?.base64URLencoded()
            
            guard base64UrlHeader != nil && encodedPayloadIV != nil && encodedCipherText != nil && encodedAuthTag != nil else { return nil }
            
            encryptedPayload = "\(base64UrlHeader!).\(encodedCekCt).\(encodedPayloadIV!).\(encodedCipherText!).\(encodedAuthTag!)"
        }
        
        return encryptedPayload
    }
    
    func decrypt(_ sharedSecret: Data) throws -> String? {
        guard header != nil else {
            throw JWTError.headerNotSpecified
        }
        
        if (header?.alg == .A256GCMKW && header?.enc == .A256GCM) {
            guard header!.iv != nil else {
                throw JWTError.headersIVNotSpecified
            }
            
            guard header!.tag != nil else {
                throw JWTError.headersTagNotSpecified
            }
            
            guard ct != nil && tag != nil else { return nil }
            guard let cek = A256GCMDecryptData(sharedSecret, data: cekCt!, iv: header!.iv! as Data, tag: header!.tag! as Data, aad: nil) else { return nil }
            
            let jwe = encryptedPayload!.components(separatedBy: ".")
            let aad = jwe[0].data(using: String.Encoding.utf8)
            
            // ensure that we have 16 bytes in Authentication Tag
            if ((tag?.count)! < JWE.AuthenticationTagSize) {
                let concatedCtAndTag = NSMutableData(data: ct!)
                concatedCtAndTag.append(tag!)
                if (concatedCtAndTag.length > JWE.AuthenticationTagSize) {
                    ct = concatedCtAndTag.subdata(with: NSRange(location: 0, length: concatedCtAndTag.length-JWE.AuthenticationTagSize))
                    tag = concatedCtAndTag.subdata(with: NSRange(location: concatedCtAndTag.length-JWE.AuthenticationTagSize, length: JWE.AuthenticationTagSize))
                }
            }
            
            let data = A256GCMDecryptData(cek, data: ct!, iv: iv!, tag: tag!, aad: aad)
            decryptedPayload = String(data: data!, encoding: String.Encoding.utf8)
        }
        
        return decryptedPayload
    }
    
    class func decrypt<T>(_ encryptedData: String?, expectedKeyId: String?, secret: Data) -> T? where T: Serializable {
        guard let encryptedData = encryptedData else { return nil }
        
        let jweResult = JWE(payload: encryptedData)
        
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
        
        let jweResult = JWE(payload: encryptedData)
        
        if let expectedKeyId = expectedKeyId {
            guard jweResult.header?.kid == expectedKeyId else { return nil }
        }
        
        guard let decryptResult = try? jweResult.decrypt(secret) else { return nil }
        guard jweResult.header?.cty == "JWT" else { return nil }
        
        let jws = try? JWS(token: decryptResult!)
        let payload = jws?.body["data"] as? String
        
        return payload
        
    }
    
    // MARK: - Private Functions
    
    private func A256GCMDecryptData(_ cipherKey: Data, data: Data, iv: Data, tag: Data, aad: Data?) -> Data? {
        // cryptAuth expects that data will be with tag
        // so appending tag to data
        var dataWithTag = data
        dataWithTag.append(tag)
        
        var decryptedData: Data? = nil
        do {
            decryptedData = try CC.cryptAuth(.decrypt,
                                             blockMode: .gcm,
                                             algorithm: .aes,
                                             data: dataWithTag,
                                             aData: aad ?? Data(),
                                             key: cipherKey,
                                             iv: iv,
                                             tagLength: JWE.AuthenticationTagSize)
        } catch {
            log.error("JWT: Can't decrypt data with a256gcm. Error: \(error).")
        }
        
        return decryptedData
    }
    
    private func A256GCMEncryptData(_ key: Data, data: Data, iv: Data, aad: Data?) -> (Data?, Data?) {
        var encryptResult: (Data?, Data?) = (nil, nil)
        
        do {
            let encryptedWithTag = try CC.cryptAuth(.encrypt,
                                                    blockMode: .gcm,
                                                    algorithm: .aes,
                                                    data: data,
                                                    aData: aad ?? Data(),
                                                    key: key,
                                                    iv: iv,
                                                    tagLength: JWE.AuthenticationTagSize)
            
            let cipherText = encryptedWithTag.subdata(in: 0..<(encryptedWithTag.count-JWE.AuthenticationTagSize))
            let tag = encryptedWithTag.subdata(in: (encryptedWithTag.count-JWE.AuthenticationTagSize)..<encryptedWithTag.count)
            
            encryptResult = (cipherText, tag)
        } catch  {
            log.error("JWT: Can't encrypt data with a256gcm. Error: \(error).")
        }
        
        return encryptResult
    }
}
