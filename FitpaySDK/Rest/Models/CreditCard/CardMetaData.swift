import Foundation

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
        
    weak var client: RestClient? {
        didSet {
            brandLogo?.forEach({ $0.client = client })
            cardBackground?.forEach({ $0.client = client })
            cardBackgroundCombined?.forEach({ $0.client = client })
            cardBackgroundCombinedEmbossed?.forEach({ $0.client = client })
            coBrandLogo?.forEach({ $0.client = client })
            icon?.forEach({ $0.client = client })
            issuerLogo?.forEach({ $0.client = client })
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
    
}
