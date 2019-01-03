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
        // TODO: provide expected link
        expect(self.rootLinks.termsResourceKeyLink?.href).to(equal(""))
        
        rootLinks?.links = nil
        
        expect(self.rootLinks.termsResourceKeyLink).to(beNil())
    }
    
    func testPrivacyPolicyResourceKeyLink() {
        expect(self.rootLinks.privacyPolicyResourceKeyLink?.templaced).to(beTrue())
        // TODO: provide expected link
        expect(self.rootLinks.privacyPolicyResourceKeyLink?.href).to(equal(""))
        
        rootLinks?.links = nil
        
        expect(self.rootLinks.privacyPolicyResourceKeyLink).to(beNil())
    }
    
}
