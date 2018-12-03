import XCTest
import Nimble

@testable import FitpaySDK

class CountryTests: XCTestCase {
    
    private let mockModels = MockModels()
    private let mockRestRequest = MockRestRequest()
    private var session: RestSession?
    private var client: RestClient?
    
    override func setUp() {
        session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session!.accessToken = "authorized"
        
        client = RestClient(session: session!, restRequest: mockRestRequest)
    }
    
    func testCountryParsing() {
        let country = mockModels.getCountry()
        
        expect(country?.iso).to(equal("US"))
        expect(country?.name).to(equal("United States"))
        
        expect(country?.links?.count).to(equal(1))
        
        let json = country?.toJSON()
        expect(json?["iso"] as? String).to(equal("US"))
        expect(json?["name"] as? String).to(equal("United States"))
        expect(json?["_links"]).toNot(beNil())
    }
    
    func testProvincesAvailable() {
        let country = mockModels.getCountry()
        
        let provincesAvailable = country?.provincesAvailable
        expect(provincesAvailable).to(beTrue())
        
        country?.links = nil
        
        let provincesNotAvailable = country?.provincesAvailable
        expect(provincesNotAvailable).to(beFalse())
    }
    
    func testGetProvincesNoClient() {
        let country = mockModels.getCountry()

        country?.getProvinces { (provinceCollection, error) in
            expect(provinceCollection).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testGetProvinces() {
        let country = mockModels.getCountry()
        country?.client = client
        
        country?.getProvinces { (provinceCollection, error) in
            expect(provinceCollection?.provinceList.count).to(beGreaterThan(0))
            expect(error).to(beNil())
        }
    }
    
}
