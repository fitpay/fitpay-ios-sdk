import Foundation

/// Representation of a Secure Element
@objc open class SecureElement: NSObject, Codable {
    
    /// The ID of a secure element in a payment capable device
    @objc open var secureElementId: String?
    
    /// Controlling authority security domain certificate
    /// Like an SSL certificate, but for secure elements
    @objc open var casdCert: String?
    
    /// Initialize class with all variables
    @objc public init(secureElementId: String?, casdCert: String?) {
        super.init()
        self.secureElementId = secureElementId
        self.casdCert = casdCert
    }
    
}
