import XCTest
import Nimble

@testable import FitpaySDK

class IdVerificationTests: XCTestCase {
    
    func testEmptyInitializerSetsLocale() {
        let verificationResponse = IdVerification()
        
        expect(verificationResponse.locale).to(equal("en-US"))
    }
    
    func testLocaleIsIncludedInJSON() {
        let verificationResponse = IdVerification()
        
        //locale is private so we will test the json output
        let verificationResonseJson = verificationResponse.toJSON()
        
        expect(verificationResonseJson?["locale"] as? String).to(equal("en-US"))
    }
    
    func testLocaleNotOverridenWithJsonInitializer() {
        let verificationResponse = try? IdVerification(["locale": "wrong"])
        
        expect(verificationResponse).toNot(beNil())
        expect(verificationResponse!.locale).to(equal("en-US"))
    }
    
    func testIdVerificationParsing() {
        let mockModels = MockModels()
        let idVerification = mockModels.getIdVerification()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        expect(idVerification).toNot(beNil())
        
        expect(idVerification?.lastOemAccountActivityDate).toNot(beNil())
        expect(idVerification?.deviceLostModeDate).toNot(beNil())
        expect(idVerification?.devicePairedToOemAccountDate).toNot(beNil())
        
        expect(idVerification?.oemAccountInfoUpdatedDate).to(equal(dateFormatter.date(from: mockModels.someDate2)))
        expect(idVerification?.oemAccountCreatedDate).to(equal(dateFormatter.date(from: mockModels.someDate2)))
        expect(idVerification?.suspendedCardsInOemAccount).to(equal(1))
        expect(idVerification?.devicesWithIdenticalActiveToken).to(equal(2))
        expect(idVerification?.activeTokensOnAllDevicesForOemAccount).to(equal(3))
        expect(idVerification?.oemAccountScore).to(equal(4))
        expect(idVerification?.deviceScore).to(equal(5))
        expect(idVerification?.nfcCapable).to(equal(false))
        expect(idVerification?.oemAccountCountryCode).to(equal("US"))
        expect(idVerification?.deviceCountry).to(equal("US"))
        expect(idVerification?.oemAccountUserName).to(equal(mockModels.someName))
        expect(idVerification?.devicePairedToOemAccountDate).to(equal(dateFormatter.date(from: mockModels.someDate2)))
        expect(idVerification?.deviceTimeZone).to(equal("CST"))
        expect(idVerification?.deviceTimeZoneSetBy).to(equal(0))
        expect(idVerification?.deviceIMEI).to(equal("123456"))
        
        let json = idVerification?.toJSON()
        expect(json).toNot(beNil())
        
        expect(json?["daysSinceLastAccountActivity"] as? Int).toNot(beNil())
        expect(json?["deviceLostMode"] as? Int).toNot(beNil())
        
        expect(dateFormatter.date(from: json!["oemAccountInfoUpdatedDate"] as! String)).to(equal(dateFormatter.date(from: mockModels.someDate2)))
        expect(dateFormatter.date(from: json!["oemAccountCreatedDate"] as! String)).to(equal(dateFormatter.date(from: mockModels.someDate2)))
        expect(json?["suspendedCardsInAccount"] as? Int).to(equal(1))
        expect(json?["deviceWithActiveTokens"] as? Int).to(equal(2))
        expect(json?["activeTokenOnAllDevicesForAccount"] as? Int).to(equal(3))
        expect(json?["accountScore"] as? Int).to(equal(4))
        expect(json?["deviceScore"] as? Int).to(equal(5))
        expect(json?["nfcCapable"] as? Bool).to(equal(false))
        expect(json?["oemAccountCountryCode"] as? String).to(equal("US"))
        expect(json?["deviceCountry"] as? String).to(equal("US"))
        expect(json?["oemAccountUserName"] as? String).to(equal(mockModels.someName))
        expect(dateFormatter.date(from: json!["devicePairedToOemAccountDate"] as! String)).to(equal(dateFormatter.date(from: mockModels.someDate2)))
        expect(json?["deviceTimeZone"] as? String).to(equal("CST"))
        expect(json?["deviceTimeZoneSetBy"] as? Int).to(equal(0))
        expect(json?["deviceIMEI"] as? String).to(equal("123456"))
        
    }
    
}
