import Foundation

@objcMembers open class CreditCard: NSObject, ClientModel, Serializable, SecretApplyable {

    open var creditCardId: String?
    open var userId: String?
    open var isDefault: Bool?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var state: TokenizationState?
    open var cardType: String?
    open var cardMetaData: CardMetadata?
    open var termsAssetId: String?
    open var termsAssetReferences: [TermsAssetReferences]?
    open var eligibilityExpiration: String?
    open var eligibilityExpirationEpoch: TimeInterval?
    open var deviceRelationships: [DeviceRelationships]?
    open var targetDeviceId: String?
    open var targetDeviceType: String?
    open var verificationMethods: [VerificationMethod]?
    open var externalTokenReference: String?
    open var info: CardInfo?
    open var pan: String?
    open var expMonth: Int?
    open var expYear: Int?
    open var cvv: String?
    open var name: String?
    open var address: Address?
    open var topOfWalletAPDUCommands: [APDUCommand]?
    open var tokenLastFour: String?
    
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

    private weak var _client: RestClientInterface?

    var client: RestClientInterface? {
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

            if let deviceRelationships = self.deviceRelationships {
                for deviceRelationship in deviceRelationships {
                    deviceRelationship.client = self.client
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
        case pan
        case expMonth
        case expYear
        case cvv
        case name
        case address
        case topOfWalletAPDUCommands = "offlineSeActions.topOfWallet.apduCommands"
        case tokenLastFour
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
        cardType = try? container.decode(.cardType)
        cardMetaData = try? container.decode(.cardMetaData)
        termsAssetId = try? container.decode(.termsAssetId)
        termsAssetReferences =  try? container.decode(.termsAssetReferences)
        eligibilityExpiration = try? container.decode(.eligibilityExpiration)
        eligibilityExpirationEpoch = try container.decode(.eligibilityExpirationEpoch, transformer: NSTimeIntervalTypeTransform())
        deviceRelationships = try? container.decode(.deviceRelationships)
        encryptedData = try? container.decode(.encryptedData)
        targetDeviceId = try? container.decode(.targetDeviceId)
        targetDeviceType = try? container.decode(.targetDeviceType)
        verificationMethods = try? container.decode(.verificationMethods)
        externalTokenReference = try? container.decode(.externalTokenReference)
        pan = try? container.decode(.pan)
        expMonth = try? container.decode(.expMonth)
        expYear = try? container.decode(.expYear)
        cvv = try? container.decode(.cvv)
        name = try? container.decode(.name)
        address = try? container.decode(.address)
        topOfWalletAPDUCommands = try? container.decode(.topOfWalletAPDUCommands)
        tokenLastFour = try? container.decode(.tokenLastFour)
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
        try? container.encode(cardType, forKey: .cardType)
        try? container.encode(cardMetaData, forKey: .cardMetaData)
        try? container.encode(termsAssetId, forKey: .termsAssetId)
        try? container.encode(termsAssetReferences, forKey: .termsAssetReferences)
        try? container.encode(eligibilityExpiration, forKey: .eligibilityExpiration)
        try? container.encode(eligibilityExpirationEpoch, forKey: .eligibilityExpirationEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(deviceRelationships, forKey: .deviceRelationships)
        try? container.encode(encryptedData, forKey: .encryptedData)
        try? container.encode(targetDeviceId, forKey: .targetDeviceId)
        try? container.encode(targetDeviceType, forKey: .targetDeviceType)
        try? container.encode(verificationMethods, forKey: .verificationMethods)
        try? container.encode(externalTokenReference, forKey: .externalTokenReference)
        try? container.encode(pan, forKey: .pan)
        try? container.encode(expMonth, forKey: .expMonth)
        try? container.encode(expYear, forKey: .expYear)
        try? container.encode(cvv, forKey: .cvv)
        try? container.encode(name, forKey: .name)
        try? container.encode(address, forKey: .address)
        try? container.encode(topOfWalletAPDUCommands, forKey: .topOfWalletAPDUCommands)
        try? container.encode(tokenLastFour, forKey: .tokenLastFour)
    }
    
    func applySecret(_ secret: Foundation.Data, expectedKeyId: String?) {
        self.info = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
    }

    /**
     Get the the credit card. This is useful for updated the card with the most recent data and some properties change asynchronously

     - parameter completion:   CreditCardHandler closure
     */
    @objc open func getCreditCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResourceKey
        let url = self.links?.url(resource)

        if let url = url, let client = self.client {
            client.retrieveCreditCard(url, completion: completion)
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
     - @param acceptTermsUrl url
     */
    @objc open func setAcceptTermsUrl(acceptTermsUrl: String) throws {
        guard let link = self.links?.indexOf(CreditCard.acceptTermsResourceKey) else {
            throw  AcceptTermsError.NoTerms("The card is not in a state to accept terms anymore")
        }
        
        link.href = acceptTermsUrl
    }
    
    /**
     Delete a single credit card from a user's profile. If you delete a card that is currently the default source, then the most recently added source will become the new default.
     
     - parameter completion:   DeleteCreditCardHandler closure
     */
    @objc open func deleteCreditCard(_ completion: @escaping RestClient.DeleteHandler) {
        let resource = CreditCard.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.deleteCreditCard(url, completion: completion)
        } else {
            completion(ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }

    /**
     Update the details of an existing credit card
     
     - parameter name:         name
     - parameter street1:      address
     - parameter street2:      address
     - parameter city:         city
     - parameter state:        state
     - parameter postalCode:   postal code
     - parameter countryCode:  country code
     - parameter completion:   UpdateCreditCardHandler closure
     */
    @objc open func update(name: String?,
                           street1: String?,
                           street2: String?,
                           city: String?,
                           state: String?,
                           postalCode: String?,
                           countryCode: String?,
                           completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.updateCreditCard(url,
                                    name: name,
                                    street1: street1,
                                    street2: street2,
                                    city: city,
                                    state: state,
                                    postalCode: postalCode,
                                    countryCode: countryCode,
                                    completion: completion)
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
            client.acceptTerms(url, completion: completion)
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
            client.declineTerms(url, completion: completion)
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
            client.deactivate(url, causedBy: causedBy, reason: reason, completion: completion)
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
            client.reactivate(url, causedBy: causedBy, reason: reason, completion: completion)
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
            client.transactions(url, limit: limit, offset: offset, completion: completion)
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
            client.getVerificationMethods(url, completion: completion)
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
            client.getVerificationMethod(url, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: CreditCard.self, client: client, url: url, resource: resource))
        }
    }
}

open class CardMetadata: NSObject, ClientModel, Serializable {
    
    open var foregroundColor: String? // TODO: update to UIColor
    open var issuerName: String?
    open var shortDescription: String?
    open var longDescription: String?
    open var contactUrl: String?
    open var contactPhone: String?
    open var contactEmail: String?
    open var termsAndConditionsUrl: String?
    open var privacyPolicyUrl: String?
    open var brandLogo: [Image]?
    open var cardBackground: [Image]?
    open var cardBackgroundCombined: [ImageWithOptions]?
    open var cardBackgroundCombinedEmbossed: [ImageWithOptions]?
    open var coBrandLogo: [Image]?
    open var icon: [Image]?
    open var issuerLogo: [Image]?
    
    private var _client: RestClientInterface?
    
    var client: RestClientInterface? {
        get {
            return self._client
        }

        set {
            self._client = newValue

            if let brandLogo = self.brandLogo {
                for image in brandLogo {
                    image.client = self.client
                }
            }

            if let cardBackground = self.cardBackground {
                for image in cardBackground {
                    image.client = self.client
                }
            }

            if let cardBackgroundCombined = self.cardBackgroundCombined {
                for image in cardBackgroundCombined {
                    image.client = self.client
                }
            }
            
            if let cardBackgroundCombinedEmbossed = self.cardBackgroundCombinedEmbossed {
                for image in cardBackgroundCombinedEmbossed {
                    image.client = self.client
                }
            }

            if let coBrandLogo = self.coBrandLogo {
                for image in coBrandLogo {
                    image.client = self.client
                }
            }

            if let icon = self.icon {
                for image in icon {
                    image.client = self.client
                }
            }

            if let issuerLogo = self.issuerLogo {
                for image in issuerLogo {
                    image.client = self.client
                }
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case foregroundColor
        case issuerName
        case shortDescription
        case longDescription
        case contactUrl
        case contactPhone
        case contactEmail
        case termsAndConditionsUrl
        case privacyPolicyUrl
        case brandLogo
        case cardBackground
        case cardBackgroundCombined
        case cardBackgroundCombinedEmbossed
        case coBrandLogo
        case icon
        case issuerLogo
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        foregroundColor = try? container.decode(.foregroundColor)
        issuerName = try? container.decode(.issuerName)
        shortDescription = try? container.decode(.shortDescription)
        longDescription = try? container.decode(.longDescription)
        contactUrl = try? container.decode(.contactUrl)
        contactPhone = try? container.decode(.contactPhone)
        contactEmail = try? container.decode(.contactEmail)
        termsAndConditionsUrl = try? container.decode(.termsAndConditionsUrl)
        privacyPolicyUrl = try? container.decode(.privacyPolicyUrl)
        brandLogo = try? container.decode(.brandLogo)
        cardBackground = try? container.decode(.cardBackground)
        cardBackgroundCombined = try? container.decode(.cardBackgroundCombined)
        cardBackgroundCombinedEmbossed = try? container.decode(.cardBackgroundCombinedEmbossed)
        coBrandLogo = try? container.decode(.coBrandLogo)
        icon = try? container.decode(.icon)
        issuerLogo = try? container.decode(.issuerLogo)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(foregroundColor, forKey: .foregroundColor)
        try? container.encode(issuerName, forKey: .issuerName)
        try? container.encode(shortDescription, forKey: .shortDescription)
        try? container.encode(longDescription, forKey: .longDescription)
        try? container.encode(contactUrl, forKey: .contactUrl)
        try? container.encode(contactPhone, forKey: .contactPhone)
        try? container.encode(contactEmail, forKey: .contactEmail)
        try? container.encode(termsAndConditionsUrl, forKey: .termsAndConditionsUrl)
        try? container.encode(privacyPolicyUrl, forKey: .privacyPolicyUrl)
        try? container.encode(brandLogo, forKey: .brandLogo)
        try? container.encode(cardBackground, forKey: .cardBackground)
        try? container.encode(cardBackgroundCombined, forKey: .cardBackgroundCombined)
        try? container.encode(cardBackgroundCombinedEmbossed, forKey: .cardBackgroundCombinedEmbossed)
        try? container.encode(coBrandLogo, forKey: .coBrandLogo)
        try? container.encode(icon, forKey: .icon)
        try? container.encode(issuerLogo, forKey: .issuerLogo)
    }
}

open class TermsAssetReferences: NSObject, ClientModel, Serializable, AssetRetrivable {
    open var mimeType: String?
    
    var client: RestClientInterface?
    var links: [ResourceLink]?

    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case mimeType
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        mimeType = try? container.decode(.mimeType)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(mimeType, forKey: .mimeType)
    }

    @objc open func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler) {
        let resource = TermsAssetReferences.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.assets(url, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: TermsAssetReferences.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
}

open class DeviceRelationships: NSObject, ClientModel, Serializable {
    
    open var deviceType: String?
    open var deviceIdentifier: String?
    open var manufacturerName: String?
    open var deviceName: String?
    open var serialNumber: String?
    open var modelNumber: String?
    open var hardwareRevision: String?
    open var firmwareRevision: String?
    open var softwareRevision: String?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var osName: String?
    open var systemId: String?

    var client: RestClientInterface?
    var links: [ResourceLink]?

    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case deviceType
        case links = "_links"
        case deviceIdentifier
        case manufacturerName
        case deviceName
        case serialNumber
        case modelNumber
        case hardwareRevision
        case firmwareRevision
        case softwareRevision
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case osName
        case systemId
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        deviceType = try? container.decode(.deviceType)
        deviceIdentifier = try? container.decode(.deviceIdentifier)
        manufacturerName = try? container.decode(.manufacturerName)
        deviceName = try? container.decode(.deviceName)
        serialNumber = try? container.decode(.serialNumber)
        modelNumber = try? container.decode(.modelNumber)
        hardwareRevision = try? container.decode(.hardwareRevision)
        firmwareRevision =  try? container.decode(.firmwareRevision)
        softwareRevision = try? container.decode(.softwareRevision)
        created = try? container.decode(.created)
        createdEpoch = try container.decode(.createdEpoch, transformer: NSTimeIntervalTypeTransform())
        osName = try? container.decode(.osName)
        systemId = try? container.decode(.systemId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(deviceType, forKey: .deviceType)
        try? container.encode(deviceIdentifier, forKey: .deviceIdentifier)
        try? container.encode(manufacturerName, forKey: .manufacturerName)
        try? container.encode(deviceName, forKey: .deviceName)
        try? container.encode(serialNumber, forKey: .serialNumber)
        try? container.encode(modelNumber, forKey: .modelNumber)
        try? container.encode(hardwareRevision, forKey: .hardwareRevision)
        try? container.encode(firmwareRevision, forKey: .firmwareRevision)
        try? container.encode(softwareRevision, forKey: .softwareRevision)
        try? container.encode(created, forKey: .created)
        try? container.encode(createdEpoch, forKey: .createdEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(osName, forKey: .osName)
        try? container.encode(systemId, forKey: .systemId)
    }

    @objc func relationship(_ completion: @escaping RestClient.RelationshipHandler) {
        let resource = DeviceRelationships.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.relationship(url, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: DeviceRelationships.self, client: client, url: url, resource: resource))
        }
    }
}

open class CardInfo: Serializable {
    open var pan: String?
    open var expMonth: Int?
    open var expYear: Int?
    open var cvv: String?
    open var creditCardId: String?
    open var name: String?
    open var address: Address?

    private enum CodingKeys: String, CodingKey {
        case pan
        case creditCardId
        case expMonth
        case expYear
        case cvv
        case name
        case address
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        pan = try? container.decode(.pan)
        creditCardId = try? container.decode(.creditCardId)
        expMonth = try? container.decode(.expMonth)
        expYear = try? container.decode(.expYear)
        cvv = try? container.decode(.cvv)
        name = try? container.decode(.name)
        address = try? container.decode(.address)
        name = try? container.decode(.name)
    }

}

// MARK: - Nested Objects

extension CreditCard {
    
    public enum TokenizationState: String, Codable {
        case NEW,
        NOT_ELIGIBLE,
        ELIGIBLE,
        DECLINED_TERMS_AND_CONDITIONS,
        PENDING_ACTIVE,
        PENDING_VERIFICATION,
        DELETED,
        ACTIVE,
        DEACTIVATED,
        ERROR,
        DECLINED
    }
    
    enum AcceptTermsError: Error {
        case NoTerms(String)
    }

}

/**
 Identifies the party initiating the deactivation/reactivation request
 
 - CARDHOLDER: card holder
 - ISSUER:     issuer
 */
public enum CreditCardInitiator: String {
    case cardholder = "CARDHOLDER"
    case issuer = "ISSUER"
}
