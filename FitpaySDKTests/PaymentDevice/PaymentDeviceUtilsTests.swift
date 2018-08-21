import XCTest
import Nimble

@testable import FitpaySDK

class PaymentDeviceUtilsTests: XCTestCase {
    
    func testshortPreferredLanguage() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "es", languageCode: "unused", regionCode: "US")
        
        expect(locale).to(equal("es-US"))
    }
    
    func testCorrectlyFormattedPreferredLanguage() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "es-US", languageCode: "unused", regionCode: "unused")
        
        expect(locale).to(equal("es-US"))
    }
    
    func testISO6392ShortLanguage() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "haw", languageCode: "es", regionCode: "US")
        
        expect(locale).to(equal("es-US"))
    }
    
    func testISO6392fullLanguage() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "haw-US", languageCode: "es", regionCode: "unused")
        
        expect(locale).to(equal("es-US"))
    }
    
    func testScriptfullLanguage() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "zh-Hant-HK", languageCode: "unused", regionCode: "unused")
        
        expect(locale).to(equal("zh-HK"))
    }
    
    func testISO6392ScriptfullLanguage() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "haw-Hant-HK", languageCode: "es", regionCode: "unused")
        
        expect(locale).to(equal("es-HK"))
    }
    
    func testLanguageRegionFallbackCase() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "bad", languageCode: "es", regionCode: "US")
        
        expect(locale).to(equal("es-US"))
    }
    
    func testNilCase() {
        let locale = PaymentDeviceUtils.getStandardLocale(preferredLanguage: "bad", languageCode: "bad", regionCode: "bad")
        
        expect(locale).to(beNil())
    }

}
