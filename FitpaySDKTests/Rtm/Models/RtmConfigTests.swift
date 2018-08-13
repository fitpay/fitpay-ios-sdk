import XCTest
import Nimble

@testable import FitpaySDK

class RtmConfigTests: XCTestCase {
    let mockModels = MockModels()
        
    func testRtmConfigParsing() {
        let rtmConfig = mockModels.getRtmConfig()

        expect(rtmConfig?.redirectUri).to(equal("https://api.fit-pay.com"))
        expect(rtmConfig?.deviceInfo).toNot(beNil())
        expect(rtmConfig?.hasAccount).to(equal(false))
        expect(rtmConfig?.accessToken).to(equal("someToken"))

        let dict = rtmConfig?.jsonDict()
        expect(dict).toNot(beNil())

        let json = rtmConfig?.toJSON()
        expect(json?["clientId"] as? String).to(equal(mockModels.someId))
        expect(json?["redirectUri"] as? String).to(equal("https://api.fit-pay.com"))
        expect(json?["userEmail"] as? String).to(equal("someEmail"))
        expect(json?["paymentDevice"]).toNot(beNil())
        expect(json?["account"] as? Bool).to(equal(false))
        expect(json?["version"] as? String).to(equal("2"))
        expect(json?["demoMode"] as? Bool).to(equal(false))
        expect(json?["themeOverrideCssUrl"] as? String).to(equal("https://api.fit-pay.com"))
        expect(json?["demoCardGroup"] as? String).to(equal("someGroup"))
        expect(json?["accessToken"] as? String).to(equal("someToken"))
        expect(json?["language"] as? String).to(equal("en"))
        expect(json?["baseLangUrl"] as? String).to(equal("https://api.fit-pay.com"))
        expect(json?["useWebCardScanner"] as? Bool).to(equal(false))
    }
}
