import XCTest
import Nimble

@testable import FitpaySDK

class ResultCollectionTests: XCTestCase {
    let mockModels = MockModels()
        
    func testResultCollectionParsing() {
        let resultCollection = mockModels.getResultCollection()

        expect(resultCollection?.links).toNot(beNil())
        expect(resultCollection?.limit).to(equal(1))
        expect(resultCollection?.offset).to(equal(1))
        expect(resultCollection?.totalResults).to(equal(1))
        expect(resultCollection?.results).toNot(beNil())
        expect(resultCollection?.nextAvailable).to(equal(false))
        expect(resultCollection?.lastAvailable).to(equal(true))
        expect(resultCollection?.previousAvailable).to(equal(false))
        expect(resultCollection?.client).to(beNil())

        let json = resultCollection?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["limit"] as? Int).to(equal(1))
        expect(json?["offset"] as? Int).to(equal(1))
        expect(json?["totalResults"] as? Int).to(equal(1))
    }
}
