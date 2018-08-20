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
    
    private var _client: RestClient?
    
    var client: RestClient? {
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
