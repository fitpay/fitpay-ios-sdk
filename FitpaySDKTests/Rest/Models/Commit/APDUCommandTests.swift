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
    
    func testAPDUCommandParsingMissingItems() {
        let apduCommand = mockModels.getApduCommandWithMissingItems()
        
        expect(apduCommand?.groupId).to(equal(0))
        expect(apduCommand?.sequence).to(equal(0))
        expect(apduCommand?.continueOnFailure).to(beFalse())
        
        let json = apduCommand?.toJSON()

        expect(json?["groupId"] as? Int).to(equal(0))
        expect(json?["sequence"] as? Int).to(equal(0))
        expect(json?["continueOnFailure"] as? Bool).to(beFalse())
        
    }
    
    func testResponseDictionary() {
        let testResponseData = Data(base64Encoded: "eyJmb28iOiJiYXIyIn0=")

        let apduComand = mockModels.getApduCommand()
        apduComand?.responseData = testResponseData
        
        expect(apduComand?.responseDictionary["commandId"] as? String).to(equal("12345fsd"))
        expect(apduComand?.responseDictionary["responseCode"] as? String).to(equal("227d"))
        expect(apduComand?.responseDictionary["responseData"] as? String).to(equal(testResponseData?.hex))
    }
}
