
public enum VerificationMethodType: String, Serializable {
    case TEXT_TO_CARDHOLDER_NUMBER          = "TEXT_TO_CARDHOLDER_NUMBER",
        EMAIL_TO_CARDHOLDER_ADDRESS         = "EMAIL_TO_CARDHOLDER_ADDRESS",
        CARDHOLDER_TO_CALL_AUTOMATED_NUMBER = "CARDHOLDER_TO_CALL_AUTOMATED_NUMBER",
        CARDHOLDER_TO_CALL_MANNED_NUMBER    = "CARDHOLDER_TO_CALL_MANNED_NUMBER",
        CARDHOLDER_TO_VISIT_WEBSITE         = "CARDHOLDER_TO_VISIT_WEBSITE",
        CARDHOLDER_TO_USE_MOBILE_APP        = "CARDHOLDER_TO_USE_MOBILE_APP",
        ISSUER_TO_CALL_CARDHOLDER_NUMBER    = "ISSUER_TO_CALL_CARDHOLDER_NUMBER"
}

public enum VerificationState: String, Serializable {
    case AVAILABLE_FOR_SELECTION = "AVAILABLE_FOR_SELECTION",
        AWAITING_VERIFICATION    = "AWAITING_VERIFICATION",
        EXPIRED                  = "EXPIRED",
        VERIFIED                 = "VERIFIED"
}

public enum VerificationResult: String, Serializable {
    case SUCCESS                        = "SUCCESS",
        INCORRECT_CODE                  = "INCORRECT_CODE",
        INCORRECT_CODE_RETRIES_EXCEEDED = "INCORRECT_CODE_RETRIES_EXCEEDED",
        EXPIRED_CODE                    = "EXPIRED_CODE",
        INCORRECT_TAV                   = "INCORRECT_TAV",
        EXPIRED_SESSION                 = "EXPIRED_SESSION"
}

@objcMembers
open class VerificationMethod: NSObject, ClientModel, Serializable {
    
    open var verificationId: String?
    open var state: VerificationState?
    open var methodType: VerificationMethodType?
    open var value: String?
    open var verificationResult: VerificationResult?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var lastModified: String?
    open var lastModifiedEpoch: TimeInterval?
    open var verified: String?
    open var verifiedEpoch: TimeInterval?
    open var appToAppContext: A2AContext?

    weak var client: RestClient?
    
    var links: [ResourceLink]?

    open var selectAvailable: Bool {
        return self.links?.url(VerificationMethod.selectResourceKey) != nil
    }

    open var verifyAvailable: Bool {
        return self.links?.url(VerificationMethod.verifyResourceKey) != nil
    }

    open var cardAvailable: Bool {
        return self.links?.url(VerificationMethod.cardResourceKey) != nil
    }

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case verificationId
        case state
        case methodType
        case value
        case verificationResult
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case lastModified = "lastModifiedTs"
        case lastModifiedEpoch = "lastModifiedTsEpoch"
        case verified = "verifiedTs"
        case verifiedEpoch = "verifiedTsEpoch"
        case appToAppContext
    }

    private static let selectResourceKey = "select"
    private static let verifyResourceKey = "verify"
    private static let cardResourceKey = "card"

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        verificationId = try? container.decode(.verificationId)
        state = try? container.decode(.state)
        methodType = try? container.decode(.methodType)
        value = try? container.decode(.value)
        verificationResult = try? container.decode(.verificationResult)
        created = try? container.decode(.created)
        createdEpoch = try container.decode(.createdEpoch, transformer: NSTimeIntervalTypeTransform())
        lastModified = try? container.decode(.lastModified)
        lastModifiedEpoch = try container.decode(.lastModifiedEpoch, transformer: NSTimeIntervalTypeTransform())
        verified = try? container.decode(.verified)
        verifiedEpoch = try container.decode(.verifiedEpoch, transformer: NSTimeIntervalTypeTransform())

        appToAppContext = try? container.decode(.appToAppContext)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(verificationId, forKey: .verificationId)
        try? container.encode(state, forKey: .state)
        try? container.encode(methodType, forKey: .methodType)
        try? container.encode(value, forKey: .value)
        try? container.encode(verificationResult, forKey: .verificationResult)
        try? container.encode(created, forKey: .created)
        try? container.encode(createdEpoch, forKey: .createdEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(lastModified, forKey: .lastModified)
        try? container.encode(lastModifiedEpoch, forKey: .lastModifiedEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(verified, forKey: .verified)
        try? container.encode(verifiedEpoch, forKey: .verifiedEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(appToAppContext, forKey: .appToAppContext)
    }


    /// When an issuer requires additional authentication to verfiy the identity of the cardholder,
    /// this indicates the user has selected the specified verification method by the indicated verificationTypeId
    ///
    /// - Parameter completion: VerifyHandler closure
    @objc open func selectVerificationType(_ completion: @escaping RestClient.VerifyHandler) {
        let resource = VerificationMethod.selectResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.selectVerificationType(url, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: VerificationMethod.self, client: client, url: url, resource: resource))
        }
    }

    /// If the selected verification method requires the submission of a one time passcode (OTP), this transition will be available.
    /// Not all verification methods will require an OTP to be submitted through the FitPay API
    ///
    /// - Parameters:
    ///   - verificationCode: one time OTP
    ///   - completion: VerifyHandler closure
    @objc open func verify(_ verificationCode: String, completion: @escaping RestClient.VerifyHandler) {
        let resource = VerificationMethod.verifyResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.verify(url, verificationCode: verificationCode, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: VerificationMethod.self, client: client, url: url, resource: resource))
        }
    }

    /// Retrieves the details of an existing credit card. You need only supply the uniqueidentifier that was returned upon creation.
    ///
    /// - Parameter completion: CreditCardHandler closure
    @objc open func retrieveCreditCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = VerificationMethod.cardResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.retrieveCreditCard(url, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: VerificationMethod.self, client: client, url: url, resource: resource))
        }
    }
}
