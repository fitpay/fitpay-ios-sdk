import XCTest
@testable import FitpaySDK

class AddressTests: BaseTestProvider {
        
    func testAddressParsing() {
        let address = mockModels.getAddress()

        XCTAssertEqual(address?.street1, "1035 Pearl St")
        XCTAssertEqual(address?.street2, "5th Floor")
        XCTAssertEqual(address?.street3, "8th Floor")
        XCTAssertEqual(address?.city, "Boulder")
        XCTAssertEqual(address?.state, "CO")
        XCTAssertEqual(address?.postalCode, "80302")
        XCTAssertEqual(address?.countryCode, "US")

        let json = address?.toJSON()
        XCTAssertEqual(json?["street1"] as? String, "1035 Pearl St")
        XCTAssertEqual(json?["street2"] as? String, "5th Floor")
        XCTAssertEqual(json?["street3"] as? String, "8th Floor")
        XCTAssertEqual(json?["city"] as? String, "Boulder")
        XCTAssertEqual(json?["state"] as? String, "CO")
        XCTAssertEqual(json?["postalCode"] as? String, "80302")
        XCTAssertEqual(json?["countryCode"] as? String, "US")
    }
}
