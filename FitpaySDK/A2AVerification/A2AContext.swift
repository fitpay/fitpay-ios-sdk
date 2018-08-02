import UIKit

/// Object containing the information needed to pass into the issuer app
@objc public class A2AContext: NSObject, Serializable {
    
    /// iTunes App Id
    /// 10 digit number as a string
    /// Can be used to construct an iTunes URL as a fallback if the user doesn't have the issuer app installed
    @objc public var applicationId: String?
    
    /// The url used to be open the issuer app
    @objc public var action: String?
    
    /// The payload to send the issuer as a parameter
    /// ?a2apayload={payload}
    @objc public var payload: String?
    
}

