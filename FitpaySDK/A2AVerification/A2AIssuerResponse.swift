import Foundation

/// Helper Object to build from issuer response
/// Used in creating webURL
/// Create in `application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:])`
@objc open class A2AIssuerResponse: NSObject, Serializable {
    
    public var response: A2AStepupResult?
    public var authCode: String?

    /// Init A2AIssuerRequest
    ///
    /// - Parameters:
    ///   - response: returned as query param "stepupresponse"
    ///   - authCode: returned as query param "stepupauthcode" if applicable
    public init(response: A2AStepupResult, authCode: String?) {
        self.response = response
        self.authCode = authCode
        super.init()
    }

    /// Call to create url String
    ///
    /// - Returns: base64URLencoded object
    @objc open func getEncodedString() -> String? {
        guard let string = toJSONString() else { return nil }
        return Data(string.utf8).base64URLencoded()
    }
    
}

// MARK: - Nested Objects

extension A2AIssuerResponse {
    
    /// Result that comes back from issuer
    /// Create from response `A2AIssuerRequest.A2AStepupResult(rawValue: stepupResponse)`
    public enum A2AStepupResult: String, Serializable {
        case approved
        case declined
        case failure
    }
    
}
