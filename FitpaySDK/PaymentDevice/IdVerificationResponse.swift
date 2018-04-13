import Foundation
import ObjectMapper

open class IdVerificationResponse: NSObject, Mappable {
    
    /// Most recent date this user update their: Billing Address, Name, Email, password, 
    /// or other Personally Identifiable Information associated to their account.
    open var oemAccountInfoUpdatedDate: Date?
    
    open var oemAccountCreatedDate: Date?
    
    /// If this user has multiple devices, 
    /// how many cards are suspended in total across all devices?
    open var suspendedCardsInOemAccount: Int?
    
    ///  Date this account was previously used, never today.
    open var lastOemAccountActivityDate: Date?
    
    /// Date this device was reported lost or stolen. Don't send if you don't have it.
    open var deviceLostModeDate: Date?
    
    open var devicesWithIdenticalActiveToken: Int?
    
    /// If this user has multiple devices,
    /// how many cards are active in total across all devices?
    open var activeTokensOnAllDevicesForOemAccount: Int?

    /// between 0-9
    open var oemAccountScore: UInt8?
    
    /// between 0-9
    open var deviceScore: UInt8?
    
    /// Only needed if your device is NOT nfcCapable
    open var nfcCapable: Bool?
    
    /// Country of user's billing address in ISO 3166-1 alpha-2 format, e.g., US; maximum 2 characters
    open var billingCountryCode: String?
    
    /// Country setting of account or phone in ISO 3166-1 alpha-2 format
    open var oemAccountCountryCode: String?
    
    /// Country setting of payment device
    open var deviceCountry: String?
    
    /// First and Last name of account
    open var oemAccountUserName: String?
    
    /// What day was this device first paired with this oemAccount?
    open var devicePairedToOemAccountDate: Date?
    
    /// Time Zone Abbreviation. Example: PDT, MST
    open var deviceTimeZone: String?
    
    /// 1 - Time Zone Set by Network
    /// 2 - Time Zone Set by User
    /// 3 - Time Zone set by Device Location.
    open var deviceTimeZoneSetBy: Int?
    
    /// Only needed if your payment device has a cell connection
    open var deviceIMEI: String?
    
    open var billingLine1: String?
    open var billingLine2: String?
    open var billingCity: String?
    open var billingState: String?
    open var billingZip: String?
    
    private var locale: String? //[language designator ISO-639-1]‌‌‌‌-[region designator ISO 3166-1 alpha-2]
    
    public override init() {
        super.init()
        updateLocale()
    }
    
    public required convenience init?(map: Map) {
        self.init()
    }
    
    open func mapping(map: Map) {
        oemAccountInfoUpdatedDate <- (map["oemAccountInfoUpdatedDate"], ISO8601DateTransform())
        oemAccountCreatedDate <- (map["oemAccountCreatedDate"], ISO8601DateTransform())
        suspendedCardsInOemAccount <- map["suspendedCardsInOemAccount"]
        lastOemAccountActivityDate <- (map["lastOemAccountActivityDate"], ISO8601DateTransform())
        deviceLostModeDate <- (map["deviceLostModeDate"], ISO8601DateTransform())
        devicesWithIdenticalActiveToken <- map["devicesWithIdenticalActiveToken"]
        activeTokensOnAllDevicesForOemAccount <- map["activeTokensOnAllDevicesForOemAccount"]
        oemAccountScore <- map["oemAccountScore"]
        deviceScore <- map["deviceScore"]
        nfcCapable <- map["nfcCapable"]
        
        billingCountryCode <- map["billingCountryCode"]
        oemAccountCountryCode <- map["oemAccountCountryCode"]
        deviceCountry <- map["deviceCountry"]
        oemAccountUserName <- map["oemAccountUserName"]
        devicePairedToOemAccountDate <- (map["devicePairedToOemAccountDate"], ISO8601DateTransform())
        deviceTimeZone <- map["deviceTimeZone"]
        deviceTimeZoneSetBy <- map["deviceTimeZoneSetBy"]
        deviceIMEI <- map["deviceIMEI"]
        billingLine1 <- map["billingLine1"]
        billingLine2 <- map["billingLine2"]
        billingCity <- map["billingCity"]
        billingState <- map["billingState"]
        billingZip <- map["billingZip"]
        locale <- map["locale"]
        
        updateLocale() //needed to override locale when creating from JSON
    }
    
    private func updateLocale() {
        guard var preferredLanguage = NSLocale.preferredLanguages.first else { return }
        
        if (preferredLanguage.count == 2) {
            guard let region = NSLocale.current.regionCode else { return }
            preferredLanguage.append("-\(region)")
            locale = preferredLanguage
        } else {
            locale = preferredLanguage
        }

    }

    
}
