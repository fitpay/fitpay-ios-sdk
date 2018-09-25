import Security

class SECP256R1KeyPair {
    static let sharedInstance = SECP256R1KeyPair()
    
    private let keys: (privateKey: Data, publicKey: Data)? = try? CC.EC.generateKeyPair(256)
    private let unknownPrefix = "3059301306072a8648ce3d020106082a8648ce3d030107034200" // TODO: Bouncy Castle issue?
    
    // we should provide public key 
    // with unknown prefix
    var publicKey: String? {
        guard let keys = keys else { return nil }
        
        return unknownPrefix + keys.publicKey.hex
    }
    
    func generateSecretForPublicKey(_ publicKey: String) -> Data? {
        guard let keys = keys else { return nil }
        
        // removing prefix from public key
        let start = publicKey.index(publicKey.startIndex, offsetBy: 0)
        let end   = publicKey.index(publicKey.startIndex, offsetBy: unknownPrefix.count)
        
        let publicKeyWithoutPrefix = publicKey.replacingCharacters(in: start..<end, with: "")
        
        // compute secret for public key without prefix
        return try? CC.EC.computeSharedSecret(keys.privateKey, publicKey: publicKeyWithoutPrefix.hexToData()!)
    }
}
