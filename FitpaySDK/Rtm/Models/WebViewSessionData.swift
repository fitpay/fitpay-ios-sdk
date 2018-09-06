import Foundation

/// This data can be used to set or verify a user device relationship, retrieve commit changes for the device, etc...
open class SessionData: NSObject, Serializable {
    open var userId: String?
    open var deviceId: String?
    open var token: String?
    
    var encryptedData: String?
    
    public init(token: String, userId: String, deviceId: String) {
        self.userId = userId
        self.deviceId = deviceId
        self.token = token
    }

    func applySecret(_ secret: Data, expectedKeyId: String?) {
        if let tmpSession: SessionData = JWE.decrypt(encryptedData, expectedKeyId: expectedKeyId, secret: secret) {
            self.userId = tmpSession.userId
            self.deviceId = tmpSession.deviceId
            self.token = tmpSession.token
        }
    }
}
