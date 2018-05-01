import Foundation

struct PaymentDeviceUtils {
    
    static func getStandardLocale(preferredLanguage: String, languageCode: String, regionCode: String) -> String? {
        var locale: String? = nil
        
        if preferredLanguage.count == 5 { // best case
            locale = preferredLanguage
            
        } else if preferredLanguage.count == 2 && regionCode.count == 2 { // no region
            locale = "\(preferredLanguage)-\(regionCode)"
            
        } else if preferredLanguage.count > 5 { // not iso 639-1 language
            if let languageOnly = preferredLanguage.split(separator: "-").first,
                let regionOnly = preferredLanguage.split(separator: "-").last {
                if languageOnly.count == 2 && regionOnly.count == 2 {
                    locale = "\(languageOnly)-\(regionOnly)"
                } else if languageCode.count == 2 && regionOnly.count == 2 {
                    locale = "\(languageCode)-\(regionOnly)"
                }
            }
        }
        
        if locale == nil && languageCode.count == 2 && regionCode.count == 2 { // fallback
            locale = "\(languageCode)-\(regionCode)"
        }
        
        return locale
    }
    
}



