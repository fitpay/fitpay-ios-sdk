import Foundation

struct JWS {
    
    let header: JOSEHeader
    let body: [String: Any]
    let signature: String?
    
    init(token: String) throws {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw JWTError.invalidPartCount
        }
        
        self.header = JOSEHeader(headerPayload: parts[0])
        self.body = try JWTUtils.decodeJWTPart(parts[1])
        self.signature = parts[2]
    }
    
}
