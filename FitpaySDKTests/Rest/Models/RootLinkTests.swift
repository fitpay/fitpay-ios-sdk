import XCTest
import Alamofire
import Nimble

@testable import FitpaySDK

class RootLinksTest: XCTestCase {
    private let mockModels = MockModels()
    
    private var rootLinks: RootLinks!
    
    override func setUp() {
        rootLinks = mockModels.getRootLinks()
    }
    
    func testTermsResourceKeyLink() {
        expect(self.rootLinks.termsResourceKeyLink?.templated).to(beTrue())
        expect(self.rootLinks.termsResourceKeyLink?.href).to(equal("https://api.fit-pay.com/terms"))
        
        rootLinks?.links = nil
        
        expect(self.rootLinks.termsResourceKeyLink).to(beNil())
    }
    
    func testPrivacyPolicyResourceKeyLink() {
        expect(self.rootLinks.privacyPolicyResourceKeyLink?.templated).to(beTrue())
        expect(self.rootLinks.privacyPolicyResourceKeyLink?.href).to(equal("https://api.fit-pay.com/privacy-policy"))
        
        rootLinks?.links = nil
        
        expect(self.rootLinks.privacyPolicyResourceKeyLink).to(beNil())
    }
    
}
