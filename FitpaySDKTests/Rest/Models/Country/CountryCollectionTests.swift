import XCTest
import Nimble

@testable import FitpaySDK

class CountryCollectionTests: XCTestCase {
    
    private let mockModels = MockModels()

    func testCountryCollectionParsing() {
        let countryCollection = mockModels.getCountryCollection()
        
        expect(countryCollection?.countries["US"]).toNot(beNil())
        expect(countryCollection?.countryList.count).to(equal(1))
        
        let json = countryCollection?.toJSON()
        expect(json?["countries"]).toNot(beNil())
    }
    
}
