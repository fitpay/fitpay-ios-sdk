import Foundation

@objcMembers open class CreditCard: NSObject, ClientModel, Serializable, SecretApplyable {

    open var creditCardId: String?
    open var userId: String?
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
    open var info: CardInfo?
    open var topOfWalletAPDUCommands: [APDUCommand]?
    open var tokenLastFour: String?
    
    /// The credit card expiration month - placed directly on card in creditCardCreated Events (otherwise in CardInfo)
    open var expMonth: Int?
    
    /// The credit card expiration year in 4 digits - placed directly on card in creditCardCreated Events (otherwise in CardInfo)
    open var expYear: Int?
    
    var links: [ResourceLink]?
    var encryptedData: String?

    private static let selfResourceKey              = "self"
    private static let acceptTermsResourceKey       = "acceptTerms"
    private static let declineTermsResourceKey      = "declineTerms"
    private static let deactivateResourceKey        = "deactivate"
    private static let reactivateResourceKey        = "reactivate"
    private static let makeDefaultResourceKey       = "makeDefault"
    private static let transactionsResourceKey      = "transactions"
    private static let getVerificationMethodsKey    = "verificationMethods"
    private static let selectedVerificationKey      = "selectedVerification"

    private weak var _client: RestClient?

    var client: RestClient? {
        get {
            return self._client
        }
        set {
            self._client = newValue

            if let verificationMethods = self.verificationMethods {
                for verificationMethod in verificationMethods {
                    verificationMethod.client = self.client
                }
            }

            if let termsAssetReferences = self.termsAssetReferences {
                for termsAssetReference in termsAssetReferences {
                    termsAssetReference.client = self.client
                }
            }

            self.cardMetaData?.client = self.client
        }
    }

    open var acceptTermsAvailable: Bool {
        return self.links?.url(CreditCard.acceptTermsResourceKey) != nil
    }

    open var declineTermsAvailable: Bool {
        return self.links?.url(CreditCard.declineTermsResourceKey) != nil
    }

    open var deactivateAvailable: Bool {
        return self.links?.url(CreditCard.deactivateResourceKey) != nil
    }

    open var reactivateAvailable: Bool {
        return self.links?.url(CreditCard.reactivateResourceKey) != nil
    }

    open var makeDefaultAvailable: Bool {
        return self.links?.url(CreditCard.makeDefaultResourceKey) != nil
    }

    open var listTransactionsAvailable: Bool {
        return self.links?.url(CreditCard.transactionsResourceKey) != nil
    }

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
        case topOfWalletAPDUCommands = "offlineSeActions.topOfWallet.apduCommands"
        case tokenLastFour
        case expMonth
        case expYear
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        creditCardId = try? container.decode(.creditCardId)
        userId = try? container.decode(.userId)
        isDefault = try? container.decode(.isDefault)
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
        topOfWalletAPDUCommands = try? container.decode(.topOfWalletAPDUCommands)
        tokenLastFour = try? container.decode(.tokenLastFour)
        expMonth = try? container.decode(.expMonth)
        expYear = try? container.decode(.expYear)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(creditCardId, forKey: .creditCardId)
        try? container.encode(userId, forKey: .userId)
        try? container.encode(isDefault, forKey: .isDefault)
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
        try? container.encode(topOfWalletAPDUCommands, forKey: .topOfWalletAPDUCommands)
        try? container.encode(tokenLastFour, forKey: .tokenLastFour)
        try? container.encode(expMonth, forKey: .expMonth)
        try? container.encode(expYear, forKey: .expYear)
    }
    
    func applySecret(_ secret: Foundation.Data, expectedKeyId: String?) {
        self.info = JWE.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
    }

    /**
     Get the the credit card. This is useful for updated the card with the most recent data and some properties change asynchronously

     - parameter completion:   CreditCardHandler closure
     */
    @objc open func getCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResourceKey
        let url = self.links?.url(resource)

        if let url = url, let client = self.client {
            client.makeGetCall(url, parameters: nil, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    @objc open func getIsDefault() -> Bool {
        if let _isDefault = isDefault {
            return _isDefault
        }
        
        return false
    }

    /**
     Get acceptTerms url
     - return acceptTerms url
     */
    @objc open func getAcceptTermsUrl() -> String? {
        return self.links?.url(CreditCard.acceptTermsResourceKey)
    }

    /**
      Update acceptTerms url
     - param acceptTermsUrl url
     */
    @objc open func setAcceptTermsUrl(acceptTermsUrl: String) {
        guard let link = self.links?.elementAt(CreditCard.acceptTermsResourceKey) else {
            log.error("CREDIT_CARD: The card is not in a state to accept terms anymore")
            return
        }
        
        link.href = acceptTermsUrl
    }
    
    /**
     Delete a single credit card from a user's profile. If you delete a card that is currently the default source, then the most recently added source will become the new default.
     
     - parameter completion:   DeleteCreditCardHandler closure
     */
    @objc open func deleteCard(_ completion: @escaping RestClient.DeleteHandler) {
        let resource = CreditCard.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeDeleteCall(url, completion: completion)
        } else {
            completion(ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Update the details of an existing credit card
     
     - parameter name:         name
     - parameter address:      address
     - parameter completion:   UpdateCreditCardHandler closure
     */
    @objc open func updateCard(name: String?, address: Address, completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.updateCreditCard(url, name: name, address: address, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Indicates a user has accepted the terms and conditions presented when the credit card was first added to the user's profile
     
     - parameter completion:   AcceptTermsHandler closure
     */
    @objc open func acceptTerms(_ completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.acceptTermsResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.acceptCall(url, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Indicates a user has declined the terms and conditions. Once declined the credit card will be in a final state, no other actions may be taken
     
     - parameter completion:   DeclineTermsHandler closure
     */
    @objc open func declineTerms(_ completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.declineTermsResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.acceptCall(url, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Transition the credit card into a deactived state so that it may not be utilized for payment. This link will only be available for qualified credit cards that are currently in an active state.
     
     - parameter causedBy:     deactivation initiator
     - parameter reason:       deactivation reason
     - parameter completion:   DeactivateHandler closure
     */
    open func deactivate(causedBy: CreditCardInitiator, reason: String, completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.deactivateResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.activationCall(url, causedBy: causedBy, reason: reason, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Transition the credit card into an active state where it can be utilized for payment. This link will only be available for qualified credit cards that are currently in a deactivated state.
     
     - parameter causedBy:     reactivation initiator
     - parameter reason:       reactivation reason
     - parameter completion:   ReactivateHandler closure
     */
    open func reactivate(causedBy: CreditCardInitiator, reason: String, completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.reactivateResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.activationCall(url, causedBy: causedBy, reason: reason, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Mark the credit card as the default payment instrument. If another card is currently marked as the default, the default will automatically transition to the indicated credit card
     
     - parameter completion:   MakeDefaultHandler closure
     */
    @objc open func makeDefault(_ completion: @escaping RestClient.CreditCardTransitionHandler) {
        let resource = CreditCard.makeDefaultResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeDefault(url, completion: completion)
        } else {
            completion(false, nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Provides a transaction history (if available) for the user, results are limited by provider.
     
     - parameter limit:      max number of profiles per page
     - parameter offset:     start index position for list of entities returned
     - parameter completion: TransactionsHandler closure
     */
    open func listTransactions(limit: Int, offset: Int, completion: @escaping RestClient.TransactionsHandler) {
        let resource = CreditCard.transactionsResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeGetCall(url, limit: limit, offset: offset, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
      Provides a fresh list of available verification methods for the credit card when an issuer requires additional authentication to verify the identity of the cardholder.

     - parameter completion:   VerifyMethodsHandler closure
     */
    open func getVerificationMethods(_ completion: @escaping RestClient.VerifyMethodsHandler) {
        let resource = CreditCard.getVerificationMethodsKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeGetCall(url, parameters: nil, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
      Provides a user selected verification method

     - parameter completion:   VerifyMethodsHandler closure
     */
    open func getSelectedVerification(_ completion: @escaping RestClient.VerifyMethodHandler) {
        let resource = CreditCard.selectedVerificationKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeGetCall(url, parameters: nil, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

}

