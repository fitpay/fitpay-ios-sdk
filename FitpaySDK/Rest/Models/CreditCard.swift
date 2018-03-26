
import Foundation
import ObjectMapper

public enum TokenizationState: String
{
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

@objcMembers
open class CreditCard: NSObject, ClientModel, Mappable, SecretApplyable
{
    internal var links: [ResourceLink]?
    internal var encryptedData: String?

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

    fileprivate static let selfResource         = "self"
    fileprivate static let acceptTermsResource  = "acceptTerms"
    fileprivate static let declineTermsResource = "declineTerms"
    fileprivate static let deactivateResource   = "deactivate"
    fileprivate static let reactivateResource   = "reactivate"
    fileprivate static let makeDefaultResource  = "makeDefault"
    fileprivate static let transactionsResource = "transactions"

    fileprivate weak var _client: RestClient?

    public var client: RestClient? {
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
        return self.links?.url(CreditCard.acceptTermsResource) != nil
    }

    open var declineTermsAvailable: Bool {
        return self.links?.url(CreditCard.declineTermsResource) != nil
    }

    open var deactivateAvailable: Bool {
        return self.links?.url(CreditCard.deactivateResource) != nil
    }

    open var reactivateAvailable: Bool {
        return self.links?.url(CreditCard.reactivateResource) != nil
    }

    open var makeDefaultAvailable: Bool {
        return self.links?.url(CreditCard.makeDefaultResource) != nil
    }

    open var listTransactionsAvailable: Bool {
        return self.links?.url(CreditCard.transactionsResource) != nil
    }

    public required init?(map: Map){
    }

    open func mapping(map: Map) {
        self.links <- (map["_links"], ResourceLinkTransformType())
        self.creditCardId <- map["creditCardId"]
        self.userId <- map["userId"]
        self.isDefault <- map["default"]
        self.created <- map["createdTs"]
        self.createdEpoch <- (map["createdTsEpoch"], NSTimeIntervalTransform())
        self.state <- map["state"]
        self.cardType <- map["cardType"]
        self.cardMetaData = Mapper<CardMetadata>().map(JSONObject: map.JSON["cardMetaData"])
        self.termsAssetId <- map["termsAssetId"]
        self.termsAssetReferences <- (map["termsAssetReferences"], TermsAssetReferencesTransformType())
        self.eligibilityExpiration <- map["eligibilityExpiration"]
        self.eligibilityExpirationEpoch <- (map["eligibilityExpirationEpoch"], NSTimeIntervalTransform())
        self.deviceRelationships <- (map["deviceRelationships"], DeviceRelationshipsTransformType())
        self.encryptedData <- map["encryptedData"]
        self.targetDeviceId <- map["targetDeviceId"]
        self.targetDeviceType <- map["targetDeviceType"]
        self.verificationMethods <- (map["verificationMethods"], VerificationMethodTransformType())
        self.externalTokenReference <- map["externalTokenReference"]
        self.pan <- map["pan"]
        self.creditCardId <- map["creditCardId"]
        self.expMonth <- map["expMonth"]
        self.expYear <- map["expYear"]
        self.cvv <- map["cvv"]
        self.name <- map["name"]
        self.address = Mapper<Address>().map(JSONObject: map["address"].currentValue)
        self.name <- map["name"]
        self.topOfWalletAPDUCommands <- map["offlineSeActions.topOfWallet.apduCommands"]
    }

    func applySecret(_ secret: Foundation.Data, expectedKeyId: String?) {
        self.info = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
    }

    /**
     Get the the credit card. This is useful for updated the card with the most recent data and some properties change asynchronously

     - parameter completion:   CreditCardHandler closure
     */
    @objc open func getCreditCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = CreditCard.selfResource
        let url = self.links?.url(resource)

        if let url = url, let client = self.client {
            client.retrieveCreditCard(url, completion: completion)
        } else {
            completion(nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
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
     return self.links?.url(CreditCard.acceptTermsResource)
    }

    /**
      Update acceptTerms url
     - @param acceptTermsUrl url
     */
    @objc open func setAcceptTermsUrl(acceptTermsUrl: String) throws {
        guard let link = self.links?.indexOf(CreditCard.acceptTermsResource) else {
            throw  AcceptTermsError.NoTerms("The card is not in a state to accept terms anymore")
        }
        
        link.href = acceptTermsUrl
    }
    
    /**
     Delete a single credit card from a user's profile. If you delete a card that is currently the default source, then the most recently added source will become the new default.
     
     - parameter completion:   DeleteCreditCardHandler closure
     */
    @objc open func deleteCreditCard(_ completion: @escaping RestClient.DeleteCreditCardHandler) {
        let resource = CreditCard.selfResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.deleteCreditCard(url, completion: completion)
        } else {
            completion(NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
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
                           completion: @escaping RestClient.UpdateCreditCardHandler) {
        let resource = CreditCard.selfResource
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
            completion(nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Indicates a user has accepted the terms and conditions presented when the credit card was first added to the user's profile
     
     - parameter completion:   AcceptTermsHandler closure
     */
    @objc open func acceptTerms(_ completion: @escaping RestClient.AcceptTermsHandler) {
        let resource = CreditCard.acceptTermsResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.acceptTerms(url, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Indicates a user has declined the terms and conditions. Once declined the credit card will be in a final state, no other actions may be taken
     
     - parameter completion:   DeclineTermsHandler closure
     */
    @objc open func declineTerms(_ completion: @escaping RestClient.DeclineTermsHandler) {
        let resource = CreditCard.declineTermsResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.declineTerms(url, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Transition the credit card into a deactived state so that it may not be utilized for payment. This link will only be available for qualified credit cards that are currently in an active state.
     
     - parameter causedBy:     deactivation initiator
     - parameter reason:       deactivation reason
     - parameter completion:   DeactivateHandler closure
     */
    open func deactivate(causedBy: CreditCardInitiator, reason: String, completion: @escaping RestClient.DeactivateHandler) {
        let resource = CreditCard.deactivateResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.deactivate(url, causedBy: causedBy, reason: reason, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Transition the credit card into an active state where it can be utilized for payment. This link will only be available for qualified credit cards that are currently in a deactivated state.
     
     - parameter causedBy:     reactivation initiator
     - parameter reason:       reactivation reason
     - parameter completion:   ReactivateHandler closure
     */
    open func reactivate(causedBy: CreditCardInitiator, reason: String, completion: @escaping RestClient.ReactivateHandler) {
        let resource = CreditCard.reactivateResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.reactivate(url, causedBy: causedBy, reason: reason, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Mark the credit card as the default payment instrument. If another card is currently marked as the default, the default will automatically transition to the indicated credit card
     
     - parameter completion:   MakeDefaultHandler closure
     */
    @objc open func makeDefault(_ completion: @escaping RestClient.MakeDefaultHandler) {
        let resource = CreditCard.makeDefaultResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeDefault(url, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Provides a transaction history (if available) for the user, results are limited by provider.
     
     - parameter limit:      max number of profiles per page
     - parameter offset:     start index position for list of entities returned
     - parameter completion: TransactionsHandler closure
     */
    open func listTransactions(limit: Int, offset: Int, completion: @escaping RestClient.TransactionsHandler) {
        let resource = CreditCard.transactionsResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.transactions(url, limit: limit, offset: offset, completion: completion)
        } else {
            completion(nil, NSError.clientUrlError(domain: CreditCard.self, code: 0, client: client, url: url, resource: resource))
        }
    }
}

open class CardMetadata: NSObject, ClientModel, Mappable
{
    open var labelColor: String?
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
    fileprivate var _client: RestClient?
    public var client: RestClient?
    {
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

    public required init?(map: Map) {
    }

    open func mapping(map: Map) {
        self.labelColor <- map["labelColor"]
        self.issuerName <- map["issuerName"]
        self.shortDescription <- map["shortDescription"]
        self.longDescription <- map["longDescription"]
        self.contactUrl <- map["contactUrl"]
        self.contactPhone <- map["contactPhone"]
        self.contactEmail <- map["contactEmail"]
        self.termsAndConditionsUrl <- map["termsAndConditionsUrl"]
        self.privacyPolicyUrl <- map["privacyPolicyUrl"]
        self.brandLogo <- (map["brandLogo"], ImageTransformType())
        self.cardBackground <- (map["cardBackground"], ImageTransformType())
        self.cardBackgroundCombined <- (map["cardBackgroundCombined"], ImageTransformType())
        self.cardBackgroundCombinedEmbossed <- (map["cardBackgroundCombinedEmbossed"], ImageTransformType())
        self.coBrandLogo <- (map["coBrandLogo"], ImageTransformType())
        self.icon <- (map["icon"], ImageTransformType())
        self.issuerLogo <- (map["issuerLogo"], ImageTransformType())
    }
}

open class TermsAssetReferences: NSObject, ClientModel, Mappable, AssetRetrivable
{
    internal var links: [ResourceLink]?
    open var mimeType: String?
    public var client: RestClient?
    fileprivate static let selfResource = "self"

    public required init?(map: Map) {
    }

    open func mapping(map: Map) {
        self.links <- (map["_links"], ResourceLinkTransformType())
        self.mimeType <- map["mimeType"]
    }

    @objc open func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler) {
        let resource = TermsAssetReferences.selfResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.assets(url, completion: completion)
        } else {
            let error = NSError.clientUrlError(domain: TermsAssetReferences.self, code: 0, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
}

internal class TermsAssetReferencesTransformType: TransformType
{
    typealias Object = [TermsAssetReferences]
    typealias JSON = [[String: AnyObject]]

    func transformFromJSON(_ value: Any?) -> [TermsAssetReferences]? {
        if let items = value as? [[String: AnyObject]] {
            var list = [TermsAssetReferences]()

            for raw in items  {
                if let item = Mapper<TermsAssetReferences>().map(JSON: raw) {
                    list.append(item)
                }
            }

            return list
        }

        return nil
    }

    func transformToJSON(_ value: [TermsAssetReferences]?) -> [[String: AnyObject]]? {
        return nil
    }
}

open class DeviceRelationships: NSObject, ClientModel, Mappable
{
    open var deviceType: String?
    internal var links: [ResourceLink]?
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

    fileprivate static let selfResource = "self"
    public var client: RestClient?

    public required init?(map: Map) {
    }

    open func mapping(map: Map) {
        self.deviceType <- map["deviceType"]
        self.links <- (map["_links"], ResourceLinkTransformType())
        self.deviceIdentifier <- map["deviceIdentifier"]
        self.manufacturerName <- map["manufacturerName"]
        self.deviceName <- map["deviceName"]
        self.serialNumber <- map["serialNumber"]
        self.modelNumber <- map["modelNumber"]
        self.hardwareRevision <- map["hardwareRevision"]
        self.firmwareRevision <- map["firmwareRevision"]
        self.softwareRevision <- map["softwareRevision"]
        self.created <- map["createdTs"]
        self.createdEpoch <- (map["createdTsEpoch"], NSTimeIntervalTransform())
        self.osName <- map["osName"]
        self.systemId <- map["systemId"]
    }

    @objc func relationship(_ completion: @escaping RestClient.RelationshipHandler) {
        let resource = DeviceRelationships.selfResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.relationship(url, completion: completion)
        } else {
            completion(nil, NSError.clientUrlError(domain: DeviceRelationships.self, code: 0, client: client, url: url, resource: resource))
        }
    }
}

internal class DeviceRelationshipsTransformType: TransformType
{
    typealias Object = [DeviceRelationships]
    typealias JSON = [[String: AnyObject]]

    func transformFromJSON(_ value: Any?) -> [DeviceRelationships]? {
        if let items = value as? [[String: AnyObject]] {
            var list = [DeviceRelationships]()

            for raw in items {
                if let item = Mapper<DeviceRelationships>().map(JSON: raw) {
                    list.append(item)
                }
            }

            return list
        }

        return nil
    }

    func transformToJSON(_ value: [DeviceRelationships]?) -> [[String: AnyObject]]? {
        return nil
    }
}


open class CardInfo: Mappable
{
    open var pan: String?
    open var expMonth: Int?
    open var expYear: Int?
    open var cvv: String?
    open var creditCardId: String?
    open var name: String?
    open var address: Address?

    public required init?(map: Map) {
    }

    open func mapping(map: Map) {
        self.pan <- map["pan"]
        self.creditCardId <- map["creditCardId"]
        self.expMonth <- map["expMonth"]
        self.expYear <- map["expYear"]
        self.cvv <- map["cvv"]
        self.name <- map["name"]
        self.address = Mapper<Address>().map(JSONObject: map["address"].currentValue)
        self.name <- map["name"]
    }
}

/**
 Identifies the party initiating the deactivation/reactivation request
 
 - CARDHOLDER: card holder
 - ISSUER:     issuer
 */
public enum CreditCardInitiator: String {
    case CARDHOLDER
    case ISSUER
}
