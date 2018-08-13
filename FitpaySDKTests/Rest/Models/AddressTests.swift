import XCTest
import Nimble

@testable import FitpaySDK

class AddressTests: BaseTestProvider {
        
    func testAddressParsing() {
        let address = mockModels.getAddress()
        expect(address?.street1).to(equal("1035 Pearl St"))
        expect(address?.street2).to(equal("5th Floor"))
        expect(address?.street3).to(equal("8th Floor"))
        expect(address?.city).to(equal("Boulder"))
        expect(address?.state).to(equal("CO"))
        expect(address?.postalCode).to(equal("80302"))
        expect(address?.countryCode).to(equal("US"))

        let json = address?.toJSON()
        expect(json?["street1"] as? String).to(equal("1035 Pearl St"))
        expect(json?["street2"] as? String).to(equal("5th Floor"))
        expect(json?["street3"] as? String).to(equal("8th Floor"))
        expect(json?["city"] as? String).to(equal("Boulder"))
        expect(json?["state"] as? String).to(equal("CO"))
        expect(json?["postalCode"] as? String).to(equal("80302"))
        expect(json?["countryCode"] as? String).to(equal("US"))

    }
}
