import XCTest
import Nimble

@testable import FitpaySDK

class FitpayConfigTests: XCTestCase {
    
    override func tearDown() {
        FitpayConfig.configure(clientId: "fp_webapp_pJkVp2Rl")
    }

    func testConfigByClientId() {
        expect(FitpayConfig.clientId).to(beNil())
        
        FitpayConfig.configure(clientId: "testId")

        expect(FitpayConfig.clientId).to(equal("testId"))
    }
    
    func testConfigFromDefaultFile() {
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        
        FitpayConfig.configure(bundle: bundle)
        
        expect(FitpayConfig.clientId).to(equal("testId2"))
        expect(FitpayConfig.webURL).to(equal("web"))
        expect(FitpayConfig.redirectURL).to(equal("redirect"))
        expect(FitpayConfig.apiURL).to(equal("api"))
        expect(FitpayConfig.authURL).to(equal("auth"))
        expect(FitpayConfig.supportApp2App).to(equal(true))
        expect(FitpayConfig.minLogLevel).to(equal(LogLevel.debug))
        expect(FitpayConfig.Web.demoMode).to(equal(true))
        expect(FitpayConfig.Web.demoCardGroup).to(equal("visa_only"))
        expect(FitpayConfig.Web.cssURL).to(equal("css"))
        expect(FitpayConfig.Web.supportCardScanner).to(equal(true))

    }
    
    func testConfigFromNamedFile() {
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        
        FitpayConfig.configure(fileName: "fitpayconfigAlt", bundle: bundle)
        
        expect(FitpayConfig.clientId).to(equal("testId3"))
    }

    
    func testConfigFromMissingFile() {
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        
        expect(FitpayConfig.clientId).to(equal("fp_webapp_pJkVp2Rl"))
        
        FitpayConfig.configure(fileName: "fitpayconfigNotHere", bundle: bundle)
        
        expect(FitpayConfig.clientId).to(equal("fp_webapp_pJkVp2Rl"))
    }

}
