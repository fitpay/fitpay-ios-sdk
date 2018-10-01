import Foundation

@objcMembers open class VerificationMethod: NSObject, ClientModel, Serializable {
    
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
        return links?.url(VerificationMethod.selectResourceKey) != nil
    }

    open var verifyAvailable: Bool {
        return links?.url(VerificationMethod.verifyResourceKey) != nil
    }

    open var cardAvailable: Bool {
        return links?.url(VerificationMethod.cardResourceKey) != nil
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

    // MARK: - Lifecycle
    
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

    // MARK: - Public Functions
    
    /// When an issuer requires additional authentication to verfiy the identity of the cardholder,
    /// this indicates the user has selected the specified verification method by the indicated verificationTypeId
    ///
    /// - Parameter completion: VerifyHandler closure
    @objc open func selectVerificationType(_ completion: @escaping RestClient.VerifyHandler) {
        let resource = VerificationMethod.selectResourceKey
        
        guard let url = links?.url(resource), let client = client else {
             completion(false, nil, composeError(resource))
            return
        }

        client.selectVerificationType(url, completion: completion)
    }

    /// If the selected verification method requires the submission of a one time passcode (OTP), this transition will be available.
    /// Not all verification methods will require an OTP to be submitted through the FitPay API
    ///
    /// - Parameters:
    ///   - verificationCode: one time OTP
    ///   - completion: VerifyHandler closure
    @objc open func verify(_ verificationCode: String, completion: @escaping RestClient.VerifyHandler) {
        let resource = VerificationMethod.verifyResourceKey
        
        guard let url = links?.url(resource), let client = client else {
             completion(false, nil, composeError(resource))
            return
        }
        
        client.verify(url, verificationCode: verificationCode, completion: completion)
    }

    /// Retrieves the details of an existing credit card. You need only supply the unique identifier that was returned upon creation.
    ///
    /// - Parameter completion: CreditCardHandler closure
    @objc open func retrieveCreditCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = VerificationMethod.cardResourceKey
        
        guard let url = links?.url(resource), let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }
    
    // MARK: - Private Functions
    
    private func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: VerificationMethod.self, client: client, url: links?.url(resource), resource: resource)
    }
}
