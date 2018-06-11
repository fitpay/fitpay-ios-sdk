import XCTest

@testable import FitpaySDK

class IdVerificationTests: XCTestCase {

    func testEmptyInitializerSetsLocale() {
        let verificationResponse = IdVerification()
        
        XCTAssertEqual(verificationResponse.locale, "en-US")
    }
    
    func testLocaleIsIncludedInJSON() {
        let verificationResponse = IdVerification()
        
        //locale is private so we will test the json output
        let verificationResonseJson = verificationResponse.toJSON()
        
        XCTAssertEqual(verificationResonseJson?["locale"] as? String, "en-US")
    }
    
    func testLocaleNotOverridenWithJsonInitializer() {
        let verificationResponse = try? IdVerification(["locale": "wrong"])
        
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse!.locale, "en-US")
    }
    
    func testIdVerificationParsing() {
        let mockModels = MockModels()
        let idVerification = mockModels.getIdVerification()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        XCTAssertNotNil(idVerification)
        XCTAssertEqual(idVerification?.oemAccountInfoUpdatedDate, dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(idVerification?.oemAccountCreatedDate, dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(idVerification?.suspendedCardsInOemAccount, 1)
        XCTAssertEqual(idVerification?.lastOemAccountActivityDate, dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(idVerification?.deviceLostModeDate, dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(idVerification?.devicesWithIdenticalActiveToken, 2)
        XCTAssertEqual(idVerification?.activeTokensOnAllDevicesForOemAccount, 3)
        XCTAssertEqual(idVerification?.oemAccountScore, 4)
        XCTAssertEqual(idVerification?.deviceScore, 5)
        XCTAssertEqual(idVerification?.nfcCapable, false)
        XCTAssertEqual(idVerification?.billingCountryCode, "US")
        XCTAssertEqual(idVerification?.oemAccountCountryCode, "US")
        XCTAssertEqual(idVerification?.deviceCountry, "US")
        XCTAssertEqual(idVerification?.oemAccountUserName, mockModels.someName)
        XCTAssertNotNil(idVerification?.devicePairedToOemAccountDate)
        XCTAssertEqual(idVerification?.devicePairedToOemAccountDate, dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(idVerification?.deviceTimeZone, "CST")
        XCTAssertEqual(idVerification?.deviceTimeZoneSetBy, 0)
        XCTAssertEqual(idVerification?.deviceIMEI, "123456")
        XCTAssertEqual(idVerification?.billingLine1, "line 1")
        XCTAssertEqual(idVerification?.billingLine2, "line 2")
        XCTAssertEqual(idVerification?.billingCity, "St. Louis")
        XCTAssertEqual(idVerification?.billingState, "MO")
        XCTAssertEqual(idVerification?.billingZip, "12345")

        
        let json = idVerification?.toJSON()
        XCTAssertNotNil(json)
        
        XCTAssertEqual(dateFormatter.date(from: json!["oemAccountInfoUpdatedDate"] as! String), dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(dateFormatter.date(from: json!["oemAccountCreatedDate"] as! String), dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(json?["suspendedCardsInAccount"] as? Int, 1)
        XCTAssertEqual(dateFormatter.date(from: json!["daysSinceLastAccountActivity"] as! String), dateFormatter.date(from: mockModels.someDate2))
        XCTAssertNotNil(json?["deviceLostMode"] as? Int)
        
        XCTAssertEqual(json?["deviceWithActiveTokens"] as? Int, 2)
        XCTAssertEqual(json?["activeTokenOnAllDevicesForAccount"] as? Int, 3)
        XCTAssertEqual(json?["accountScore"] as? Int, 4)
        XCTAssertEqual(json?["deviceScore"] as? Int, 5)
        XCTAssertEqual(json?["nfcCapable"] as? Bool, false)
        XCTAssertEqual(json?["billingCountryCode"] as? String, "US")
        XCTAssertEqual(json?["oemAccountCountryCode"] as? String, "US")
        XCTAssertEqual(json?["deviceCountry"] as? String, "US")
        XCTAssertEqual(json?["oemAccountUserName"] as? String, mockModels.someName)
        XCTAssertEqual(dateFormatter.date(from: json!["devicePairedToOemAccountDate"] as! String), dateFormatter.date(from: mockModels.someDate2))
        XCTAssertEqual(json?["deviceTimeZone"] as? String, "CST")
        XCTAssertEqual(json?["deviceTimeZoneSetBy"] as? Int, 0)
        XCTAssertEqual(json?["deviceIMEI"] as? String, "123456")
        XCTAssertEqual(json?["billingLine1"] as? String, "line 1")
        XCTAssertEqual(json?["billingLine2"] as? String, "line 2")
        XCTAssertEqual(json?["billingCity"] as? String, "St. Louis")
        XCTAssertEqual(json?["billingState"] as? String, "MO")
        XCTAssertEqual(json?["billingZip"] as? String, "12345")
    }

}
