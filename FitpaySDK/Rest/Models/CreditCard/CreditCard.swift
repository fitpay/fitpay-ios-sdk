import Foundation

@objcMembers open class CreditCard: NSObject, ClientModel, Serializable, SecretApplyable {
    
    open var creditCardId: String?
    open var userId: String?
    
    @available(*, deprecated, message: "as of v1.0.3 - will stop being returned from the server")
    open var isDefault: Bool?
    
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var state: TokenizationState?
    open var causedBy: CreditCardInitiator?
    open var cardType: String?
    open var cardMetaData: CardMetadata?
    open var termsAssetId: String?
    open var termsAssetReferences: [TermsAssetReferences]?
    open var eligibilityExpiration: String?
    open var eligibilityExpirationEpoch: TimeInterval?
    open var targetDeviceId: String?
    open var targetDeviceType: String?
    open var verificationMethods: [VerificationMethod]?
    open var externalTokenReference: String?
    
    /// Card information
    ///
    /// parsed from encryptedData or top level object if card is from Commit
    open var info: CardInfo?
    
    open var topOfWalletAPDUCommands: [APDUCommand]?
    open var tokenLastFour: String?
    
    /// The reason a card provisioning failed. Returned in the payload of a non-apdu commit
    open var provisioningFailedReason: ProvisioningFailedReason?
    
    /// The credit card expiration month
    @available(*, deprecated, message: "as of v1.3.2 - parsed into CardInfo always")
    open var expMonth: Int?
    
    /// The credit card expiration year in 4 digits
    @available(*, deprecated, message: "as of v1.3.2 - parsed into CardInfo always")
    open var expYear: Int?
    
    /// returns true if acceptTermsResourceKey link is returned on the model and available to call
    open var acceptTermsAvailable: Bool {
        return links?[CreditCard.acceptTermsResourceKey] != nil
    }
    
    /// returns true if declineTermsResourceKey link is returned on the model and available to call
    open var declineTermsAvailable: Bool {
        return links?[CreditCard.declineTermsResourceKey] != nil
    }
    
    /// returns true if deactivateResourceKey link is returned on the model and available to call
    open var deactivateAvailable: Bool {
        return links?[CreditCard.deactivateResourceKey] != nil
    }
    
    /// returns true if reactivateResourceKey link is returned on the model and available to call
    open var reactivateAvailable: Bool {
        return links?[CreditCard.reactivateResourceKey] != nil
    }
    
    /// returns true if makeDefaultResourceKey link is returned on the model and available to call
    open var makeDefaultAvailable: Bool {
        return links?[CreditCard.makeDefaultResourceKey] != nil
    }
    
    /// returns true if transactionsResourceKey link is returned on the model and available to call
    open var listTransactionsAvailable: Bool {
        return links?[CreditCard.transactionsResourceKey] != nil
    }
    
    /// returns true if getVerificationMethodsKey link is returned on the model and available to call
    open var verificationMethodsAvailable: Bool {
        return links?[CreditCard.getVerificationMethodsKey] != nil
    }
    
    /// returns true if selectedVerificationKey link is returned on the model and available to call
    open var selectedVerificationMethodAvailable: Bool {
        return links?[CreditCard.selectedVerificationKey] != nil
    }
    
    /// returns the templated URL if webappCardKey link is returned on the model
    open var webappCardLink: Link? {
        return links?[CreditCard.webappCardKey]
    }
    
    var links: [String: Link]?
    
    var encryptedData: String?
    
    weak var client: RestClient? {
        didSet {
            verificationMethods?.forEach({ $0.client = client })
            termsAssetReferences?.forEach({ $0.client = client })
            cardMetaData?.client = client
        }
    }
    
    // nested model to parse top of wallet commands correctly
    private var offlineSeActions: OfflineSeActions?
    private struct OfflineSeActions: Codable {
        var topOfWallet: TopOfWallet?
        
        struct TopOfWallet: Codable {
            var apduCommands: [APDUCommand]?
        }
    }
    
    private static let selfResourceKey = "self"
    private static let acceptTermsResourceKey = "acceptTerms"
    private static let declineTermsResourceKey = "declineTerms"
    private static let deactivateResourceKey = "deactivate"
    private static let reactivateResourceKey = "reactivate"
    private static let makeDefaultResourceKey = "makeDefault"
    private static let transactionsResourceKey = "transactions"
    private static let getVerificationMethodsKey = "verificationMethods"
    private static let selectedVerificationKey = "selectedVerification"
    private static let webappCardKey = "webapp.card"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case creditCardId
        case userId
        case isDefault = "default"
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case state
        case causedBy
        case cardType
        case cardMetaData
        case termsAssetId
        case termsAssetReferences
        case eligibilityExpiration
        case eligibilityExpirationEpoch
        case deviceRelationships
        case encryptedData
        case targetDeviceId
        case targetDeviceType
        case verificationMethods
        case externalTokenReference
        case offlineSeActions
        case tokenLastFour
        case provisioningFailedReason = "reason"
        case expMonth
        case expYear
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try? container.decode(.links)
        creditCardId = try? container.decode(.creditCardId)
        userId = try? container.decode(.userId)
        created = try? container.decode(.created)
        createdEpoch = try container.decode(.createdEpoch, transformer: NSTimeIntervalTypeTransform())
        state = try? container.decode(.state)
        causedBy = try? container.decode(.causedBy)
        cardType = try? container.decode(.cardType)
        cardMetaData = try? container.decode(.cardMetaData)
        termsAssetId = try? container.decode(.termsAssetId)
        termsAssetReferences =  try? container.decode(.termsAssetReferences)
        eligibilityExpiration = try? container.decode(.eligibilityExpiration)
        eligibilityExpirationEpoch = try container.decode(.eligibilityExpirationEpoch, transformer: NSTimeIntervalTypeTransform())
        encryptedData = try? container.decode(.encryptedData)
        targetDeviceId = try? container.decode(.targetDeviceId)
        targetDeviceType = try? container.decode(.targetDeviceType)
        verificationMethods = try? container.decode(.verificationMethods)
        externalTokenReference = try? container.decode(.externalTokenReference)
        
        offlineSeActions = try? container.decode(.offlineSeActions)
        topOfWalletAPDUCommands = offlineSeActions?.topOfWallet?.apduCommands
        
        tokenLastFour = try? container.decode(.tokenLastFour)
        provisioningFailedReason = try? container.decode(.provisioningFailedReason)
        
        info = try? CardInfo(from: decoder)
        
        expMonth = try? container.decode(.expMonth)
        expYear = try? container.decode(.expYear)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(offlineSeActions, forKey: .offlineSeActions)
        try? container.encodeIfPresent(links, forKey: .links)
        try? container.encode(creditCardId, forKey: .creditCardId)
        try? container.encode(userId, forKey: .userId)
        try? container.encode(created, forKey: .created)
        try? container.encode(createdEpoch, forKey: .createdEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(state, forKey: .state)
        try? container.encode(causedBy, forKey: .causedBy)
        try? container.encode(cardType, forKey: .cardType)
        try? container.encode(cardMetaData, forKey: .cardMetaData)
        try? container.encode(termsAssetId, forKey: .termsAssetId)
        try? container.encode(termsAssetReferences, forKey: .termsAssetReferences)
        try? container.encode(eligibilityExpiration, forKey: .eligibilityExpiration)
        try? container.encode(eligibilityExpirationEpoch, forKey: .eligibilityExpirationEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(encryptedData, forKey: .encryptedData)
        try? container.encode(targetDeviceId, forKey: .targetDeviceId)
        try? container.encode(targetDeviceType, forKey: .targetDeviceType)
        try? container.encode(verificationMethods, forKey: .verificationMethods)
        try? container.encode(externalTokenReference, forKey: .externalTokenReference)
        try? container.encode(tokenLastFour, forKey: .tokenLastFour)
        try? container.encode(provisioningFailedReason, forKey: .provisioningFailedReason)
        try? container.encode(expMonth, forKey: .expMonth)
        try? container.encode(expYear, forKey: .expYear)
    }
    
    // MARK: - Public Functions
    
    @available(*, deprecated, message: "as of v1.0.3")
    @objc open func getIsDefault() -> Bool {
        return isDefault ?? false
    }
    
    /**
     Get acceptTerms url
     - return acceptTerms url
     */
    @objc open func getAcceptTermsUrl() -> String? {
        return links?[CreditCard.acceptTermsResourceKey]?.href
    }
    
    /**
     Update acceptTerms url
     - param acceptTermsUrl url
     */
    @objc open func setAcceptTermsUrl(acceptTermsUrl: String) {
        guard let link = links?[CreditCard.acceptTermsResourceKey] else {
            log.error("CREDIT_CARD: The card is not in a state to accept terms anymore")
            return
        }
        
        link.href = acceptTermsUrl
    }
    
    /**
     Get the the credit card. This is useful for updated the card with the most recent data and some properties change asynchronously
     
     - parameter completion:   CreditCardHandler closure
     */
    @objc open func getCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }
    
    /**
     Delete a single credit card from a user's profile. If you delete a card that is currently the default source, then the most recently added source will become the new default.
     
     - parameter completion:   DeleteCreditCardHandler closure
     */
    @objc open func deleteCard(_ completion: @escaping RestClient.DeleteHandler) {
        let resource = CreditCard.selfResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(composeError(resource))
            return
        }
        
        client.makeDeleteCall(url, completion: completion)
    }
    
    /**
     Update the details of an existing credit card
     
     - parameter name:         name
     - parameter address:      address
     - parameter completion:   UpdateCreditCardHandler closure
     */
    @objc open func updateCard(name: String?, address: Address, completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.updateCreditCard(url, name: name, address: address, completion: completion)
    }
    
    /**
     Indicates a user has accepted the terms and conditions presented when the credit card was first added to the user's profile
     
     - parameter completion:   AcceptTermsHandler closure
     */
    @objc open func acceptTerms(_ completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.acceptTermsResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(false, nil, composeError(resource))
            return
        }
        
        client.acceptCall(url, completion: completion)
    }
    
    /**
     Indicates a user has declined the terms and conditions. Once declined the credit card will be in a final state, no other actions may be taken
     
     - parameter completion:   DeclineTermsHandler closure
     */
    @objc open func declineTerms(_ completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.declineTermsResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(false, nil, composeError(resource))
            return
        }
        
        client.acceptCall(url, completion: completion)
    }
    
    /**
     Transition the credit card into a deactived state so that it may not be utilized for payment. This link will only be available for qualified credit cards that are currently in an active state.
     
     - parameter causedBy:     deactivation initiator
     - parameter reason:       deactivation reason
     - parameter completion:   DeactivateHandler closure
     */
    open func deactivate(causedBy: CreditCardInitiator, reason: String, completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.deactivateResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(false, nil, composeError(resource))
            return
        }
        
        client.activationCall(url, causedBy: causedBy, reason: reason, completion: completion)
    }
    
    /**
     Transition the credit card into an active state where it can be utilized for payment. This link will only be available for qualified credit cards that are currently in a deactivated state.
     
     - parameter causedBy:     reactivation initiator
     - parameter reason:       reactivation reason
     - parameter completion:   ReactivateHandler closure
     */
    open func reactivate(causedBy: CreditCardInitiator, reason: String, completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.reactivateResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(false, nil, composeError(resource))
            return
        }
        
        client.activationCall(url, causedBy: causedBy, reason: reason, completion: completion)
    }
    
    /**
     Mark the credit card as the default payment instrument. If another card is currently marked as the default, the default will automatically transition to the indicated credit card
     
     - parameter completion:   MakeDefaultHandler closure
     */
    @objc open func makeDefault(deviceId: String? = nil, _ completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.makeDefaultResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(false, nil, composeError(resource))
            return
        }
        
        client.makeCreditCardDefault(url, deviceId: deviceId, completion: completion)
    }
    
    /**
     Provides a transaction history (if available) for the user, results are limited by provider.
     
     - parameter limit:      max number of profiles per page
     - parameter offset:     start index position for list of entities returned
     - parameter completion: TransactionsHandler closure
     */
    open func listTransactions(limit: Int, offset: Int, completion: @escaping RestClient.TransactionsHandler) {
        let resource = CreditCard.transactionsResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, limit: limit, offset: offset, overrideHeaders: ["Accept": "application/vnd.fitpay-v2+json"], completion: completion)
    }
    
    /**
     Provides a fresh list of available verification methods for the credit card when an issuer requires additional authentication to verify the identity of the cardholder.
     
     - parameter completion:   VerifyMethodsHandler closure
     */
    open func getVerificationMethods(_ completion: @escaping RestClient.VerifyMethodsHandler) {
        let resource = CreditCard.getVerificationMethodsKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }
    
    /**
     Provides a user selected verification method
     
     - parameter completion:   VerifyMethodsHandler closure
     */
    open func getSelectedVerification(_ completion: @escaping RestClient.VerifyMethodHandler) {
        let resource = CreditCard.selectedVerificationKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }
    
    // MARK: - Internal Functions
    
    func applySecret(_ secret: Foundation.Data, expectedKeyId: String?) {
        info = JWE.decrypt(encryptedData, expectedKeyId: expectedKeyId, secret: secret)
    }
    
    // MARK: - Private Functions
    
    private func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: links?[resource]?.href, resource: resource)
    }
    
}
