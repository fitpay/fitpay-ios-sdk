import XCTest
import Nimble

@testable import FitpaySDK

class APDUCommandTests: XCTestCase {
    let mockModels = MockModels()
        
    func testAPDUCommandParsing() {
        let apduCommand = mockModels.getApduCommand()

        expect(apduCommand?.links).toNot(beNil())
        expect(apduCommand?.commandId).to(equal(mockModels.someId))
        expect(apduCommand?.groupId).to(equal(1))
        expect(apduCommand?.sequence).to(equal(1))
        expect(apduCommand?.command).to(equal("command"))
        expect(apduCommand?.type).to(equal(mockModels.someType))
        expect(apduCommand?.continueOnFailure).to(beTrue())

        let json = apduCommand?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["commandId"] as? String).to(equal(mockModels.someId))
        expect(json?["groupId"] as? Int).to(equal(1))
        expect(json?["sequence"] as? Int).to(equal(1))
        expect(json?["command"] as? String).to(equal("command"))
        expect(json?["type"] as? String).to(equal(mockModels.someType))
        expect(json?["continueOnFailure"] as? Bool).to(beTrue())

    }
}
