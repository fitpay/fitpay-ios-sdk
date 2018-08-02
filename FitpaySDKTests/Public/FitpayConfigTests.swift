import XCTest

@testable import FitpaySDK

class FitpayConfigTests: XCTestCase {
    
    override func tearDown() {
        FitpayConfig.configure(clientId: "fp_webapp_pJkVp2Rl")
    }

    func testConfigByClientId() {
        XCTAssertNil(FitpayConfig.clientId)
        
        FitpayConfig.configure(clientId: "testId")

        XCTAssertEqual(FitpayConfig.clientId, "testId")
    }
    
    func testConfigFromDefaultFile() {
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        
        FitpayConfig.configure(bundle: bundle)
        
        XCTAssertEqual(FitpayConfig.clientId, "testId2")
        XCTAssertEqual(FitpayConfig.webURL, "web")
        XCTAssertEqual(FitpayConfig.redirectURL, "redirect")
        XCTAssertEqual(FitpayConfig.apiURL, "api")
        XCTAssertEqual(FitpayConfig.authURL, "auth")
        XCTAssertEqual(FitpayConfig.supportApp2App, true)
        XCTAssertEqual(FitpayConfig.minLogLevel, LogLevel.debug)
        XCTAssertEqual(FitpayConfig.Web.demoMode, true)
        XCTAssertEqual(FitpayConfig.Web.demoCardGroup, "visa_only")
        XCTAssertEqual(FitpayConfig.Web.cssURL, "css")
        XCTAssertEqual(FitpayConfig.Web.supportCardScanner, true)

    }
    
    func testConfigFromNamedFile() {
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        
        FitpayConfig.configure(fileName: "fitpayconfigAlt", bundle: bundle)
        
        XCTAssertEqual(FitpayConfig.clientId, "testId3")
    }

}
