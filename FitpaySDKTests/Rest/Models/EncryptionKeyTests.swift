import XCTest
import Nimble

@testable import FitpaySDK

class EncryptionKeyTests: XCTestCase {
    let mockModels = MockModels()

    func testEncryptionKeyParsing() {
        let encryptionKey = mockModels.getEncryptionKey()

        expect(encryptionKey?.links).toNot(beNil())
        expect(encryptionKey?.keyId).to(equal(mockModels.someId))
        expect(encryptionKey?.created).to(equal(mockModels.someDate))
        expect(encryptionKey?.createdEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(encryptionKey?.expiration).to(equal(mockModels.someDate))
        expect(encryptionKey?.expirationEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(encryptionKey?.serverPublicKey).to(equal("someKey"))
        expect(encryptionKey?.clientPublicKey).to(equal("someKey"))
        expect(encryptionKey?.active).to(equal(true))

        let json = encryptionKey?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["keyId"] as? String).to(equal(mockModels.someId))
        expect(json?["createdTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["createdTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["expirationTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["expirationTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["serverPublicKey"] as? String).to(equal("someKey"))
        expect(json?["clientPublicKey"] as? String).to(equal("someKey"))
        expect(json?["active"] as? Bool).to(equal(true))
    }
    
    func testIsExpired() {
        let encryptionKey = mockModels.getEncryptionKey()
        
        expect(encryptionKey?.isExpired).to(beTrue())
        
        let date = Date()
        var components = DateComponents()
        components.setValue(2100, for: .year)
        let futureDate = Calendar.current.date(byAdding: components, to: date)
        
        encryptionKey?.expirationEpoch = futureDate?.timeIntervalSince1970
        
        expect(encryptionKey?.isExpired).to(beFalse())

        encryptionKey?.expirationEpoch = nil
        
        expect(encryptionKey?.isExpired).to(beFalse())

    }

}
