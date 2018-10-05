import XCTest
import Nimble

@testable import FitpaySDK

// swiftlint:disable line_length
class TestHelper {
    
    var session: RestSession!
    var client: RestClient!
    
    init(session: RestSession, client: RestClient) {
        self.session = session
        self.client = client
    }
    
    func userValid(_ user: User) {
        XCTAssertNotNil(user.created)
        XCTAssertNotNil(user.links)
        XCTAssertNotNil(user.createdEpoch)
        XCTAssertNotNil(user.encryptedData)
        XCTAssertNotNil(user.info)
        XCTAssertNotNil(user.info?.username)
        XCTAssertNotNil(user.info?.firstName)
        XCTAssertNotNil(user.info?.lastName)
        XCTAssertNotNil(user.info?.birthDate)
        XCTAssertNotNil(user.info?.email)
    }
    
    func createUser(_ expectation: XCTestExpectation, email: String, pin: String, completion: @escaping (User?) -> Void) {
        client.createUser(email, password: pin, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil, termsAccepted: nil, origin: nil, originAccountCreated: nil) { [unowned self] (user, error) in
            
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            
            self.userValid(user!)
            
            completion(user)
        }
        
    }

    func createAndLoginUser(_ expectation: XCTestExpectation, email: String = TestHelper.getEmail(), pin: String = "1234", completion: @escaping (User?) -> Void) {
        createUser(expectation, email: email, pin: pin) { (user) in
            self.session.login(username: email, password: pin) { (loginError) -> Void in
                XCTAssertNil(loginError)
                XCTAssertTrue(self.session.isAuthorized, "user should be authorized")
                
                self.client.user(id: self.session.userId!) { (user, userError) in
                    XCTAssertNotNil(user, "user should not be nuil")
                    
                    self.userValid(user!)
                    
                    XCTAssertNil(userError)
                    
                    completion(user)
                }                
            }
        }
    }
    
    func deleteUser(_ user: User?, expectation: XCTestExpectation) {
        user?.deleteUser { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
    }
    
    func createDevice(_ expectation: XCTestExpectation, user: User?, completion: @escaping (_ user: User?, _ device: Device?) -> Void) {
        let deviceType = "WATCH"
        let manufacturerName = "Fitpay"
        let deviceName = "PSPS"
        let serialNumber = "074DCC022E14"
        let modelNumber = "FB404"
        let hardwareRevision = "1.0.0.0"
        let firmwareRevision = "1030.6408.1309.0001"
        let softwareRevision = "2.0.242009.6"
        let notificationToken = "123"
        let systemId = "0x123456FFFE9ABCDE"
        let osName = "Mock OS"
        let secureElementId = self.generateRandomSeId()
        let casd = "7F2182027F7F2181DD9310043A377B2F41800171180052079414524207637093010000295F2001009501825F2404211704044501005308C4D82BA9320F14895F3781809D80F9284A961F10E30DC4296719691C37D77C6CBC488E61DAE99EABDBC6A2ED5BD728CAA71660C0C166438E175F823631976E4389F66D993D6B85541A1ED6034AD9CF51EFA9175BFD75B3EEE14209B35BC2E04CC2C92CF21C9CAB7E842727A198AA5978C230D2FFCA6B868C7E3F35415D9B3B3F0B2AE0ED3786467A8F56B6F15F38207963228E4CE54045E7B09583B81D9D7F3C47DBD1A541987B89C3EFFF058E26357F2181DD9310043A377B2F41800171180052079414524207637093010000295F2001009501885F2404211704044501005308C4D82BA9320F14895F3781800E2A33B14CDDB0DF95CBE5C4E0C3173555379C2B41B287B03848D703ED0C903AEF57E2E1FCD8B80E433FA82D0D8D22EC6AEADB5D9FF416288995C68E5E23AC1C50519C1A70EE37691CC616D21F58E292EACC9209B78FEBA6287A5A7834B410005D2F46F45B67047F6A5DFB8143453D1785CDF7D5184DBC877A91F774443C6D0D5F382072CAC0B3D5E23BD820CC057079FFA10EBBEDE961EC05F8E1F8F2CE4CE45741CB7F2181B99310043A377B2F41800171180052079414524207637093010000305F200100950200805F2404211704044501007F4946B04104CEA4915D70859D8C79884CBC6A30287D9E5D9A6A0694F0A69D41B6ACFC5A1DBC76F1A6FD629504111468F98FBD5C4281478FB3A50A492C07624B2839DAC45846F001005F374066FEB7590CEA9ADAA848059252E407D53CD59C8FC0009992E189A846BBB6A8151318A1ACC6CD61FBC1E4295160DB0784C36ED0ACAA248879CF4AFB0EFEB8409A"
        
        let secureElement = SecureElement(secureElementId: secureElementId, casdCert: casd)
        let device = Device(deviceType: deviceType, manufacturerName: manufacturerName, deviceName: deviceName, serialNumber: serialNumber,
                                modelNumber: modelNumber, hardwareRevision: hardwareRevision, firmwareRevision: firmwareRevision,
                                softwareRevision: softwareRevision, notificationToken: notificationToken, systemId: systemId, osName: osName,
                                secureElement: secureElement)
        
        user?.createDevice(device) { (device, error) -> Void in
            XCTAssertNotNil(device)
            XCTAssertNil(error)
            completion(user, device)
        }
    }
    
    func assertCreditCard(_ card: CreditCard?) {
        XCTAssertNotNil(card?.links)
        XCTAssertNotNil(card?.creditCardId)
        XCTAssertNotNil(card?.userId)
        XCTAssertNotNil(card?.created)
        XCTAssertNotNil(card?.createdEpoch)
        XCTAssertNotNil(card?.state)
        XCTAssertNotNil(card?.cardType)
        XCTAssertNotNil(card?.cardMetaData)
        XCTAssertNotNil(card?.encryptedData)
        XCTAssertNotNil(card?.info)
        XCTAssertNotNil(card?.info?.address)
        XCTAssertNotNil(card?.info?.cvv)
        XCTAssertNotNil(card?.info?.expMonth)
        XCTAssertNotNil(card?.info?.expYear)
        XCTAssertNotNil(card?.info?.pan)
    }
    
    func createEricCard(_ expectation: XCTestExpectation, pan: String, expMonth: Int, expYear: Int, user: User?, completion:@escaping (_ user: User?, _ creditCard: CreditCard?) -> Void) {
        let address = Address(street1: "4883 Dakota Blvd.", street2: "Ste. #209-A", street3: "underneath a bird's nest", city: "Boulder", state: "CO", postalCode: "80302", countryCode: "US")
        let cardInfo = CardInfo(pan: pan, expMonth: expMonth, expYear: expYear, cvv: "1234", name: "Eric Peers", address: address, riskData: nil)

        user?.createCreditCard(cardInfo: cardInfo) { [unowned self](card, error) -> Void in
            self.assertCreditCard(card)
            
            XCTAssertNil(error)
            if card?.state == .pendingActive {
                self.waitForActive(card!) { (activeCard) in
                    completion(user, activeCard)
                }
            } else {
                completion(user, card)
            }
        }
    }
    
    func createCreditCard(_ expectation: XCTestExpectation, user: User?, completion: @escaping (_ user: User?, _ creditCard: CreditCard?) -> Void) {
        let address = Address(street1: "1035 Pearl St", street2: "Street 2", street3: "Street 3", city: "Boulder", state: "CO", postalCode: "80302", countryCode: "US")
        let cardInfo = CardInfo(pan: "9999405454540004", expMonth: 10, expYear: 2018, cvv: "133", name: "TEST CARD", address: address, riskData: nil)
        
        user?.createCreditCard(cardInfo: cardInfo) { [unowned self] (card, error) -> Void in
            self.assertCreditCard(card)
            XCTAssertNil(error)
            
            if card?.state == .pendingActive {
                self.waitForActive(card!) { (activeCard) in
                    completion(user, activeCard)
                }
            } else {
                completion(user, card)
            }
        }
    }
    
    func getCreditCardsForUser(_ expectation: XCTestExpectation, user: User?, completion: @escaping (_ user: User?, _ result: ResultCollection<CreditCard>?) -> Void) {
        user?.getCreditCards(excludeState: [], limit: 10, offset: 0) { [unowned self] (result, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertNotNil(result?.limit)
            XCTAssertNotNil(result?.offset)
            XCTAssertNotNil(result?.totalResults)
            XCTAssertNotNil(result?.results)
            XCTAssertNotEqual(result?.results?.count, 0)
            XCTAssertNotNil(result?.links)
            
            if let results = result?.results {
                for card in results {
                    self.assertCreditCard(card)
                }
            }
            
            completion(user, result)
        }
    }
    
    func acceptTermsForCreditCard(_ expectation: XCTestExpectation, card: CreditCard?, completion:@escaping (_ card: CreditCard?) -> Void) {
        card?.acceptTerms { (_, acceptedCard, error) in
            
            XCTAssertNil(error)
            XCTAssertNotNil(acceptedCard)
            
            if acceptedCard?.state != .pendingVerification && acceptedCard?.state != .pendingActive {
                fail("Need to have a pending verification or active after accepting terms")
            }
            
            if acceptedCard?.state == .pendingActive {
                self.waitForActive(acceptedCard!) { (activeCard) in
                    completion(activeCard)
                }
            } else {
                completion(acceptedCard)
            }
        }
    }
    
    func editAcceptTermsUrlSuccess(_ card: CreditCard?) {
        let randomText = TestHelper.randomStringWithLength(10)
        
        //update acceptTerms url
        card?.setAcceptTermsUrl(acceptTermsUrl: randomText)
        
        //get acceptTerms url
        let acceptTermsUrl = card?.getAcceptTermsUrl()
        
        XCTAssertEqual(acceptTermsUrl, randomText)
        
    }
    
    func selectVerificationType(_ expectation: XCTestExpectation, card: CreditCard?, completion: @escaping (_ verificationMethod: VerificationMethod?) -> Void) {
        let verificationMethod = card?.verificationMethods?.first
        
        verificationMethod?.selectVerificationType { (_, verificationMethod, error) in
            XCTAssertNotNil(verificationMethod)
            XCTAssertEqual(verificationMethod?.state, .awaitingVerification)
            XCTAssertNil(error)
            
            completion(verificationMethod)
        }
    }
    
    func getVerificationMethods(_ expectation: XCTestExpectation, card: CreditCard?, completion: @escaping (_ verificationMethod: ResultCollection<VerificationMethod>?) -> Void) {
        card?.getVerificationMethods { (verificationMethods, error) in
            XCTAssertNotNil(verificationMethods, "verification methods should not be nil")
            XCTAssertNil(error)
            
            completion(verificationMethods)
        }
    }
    
    func verifyCreditCard(_ expectation: XCTestExpectation, verificationMethod: VerificationMethod?, completion: @escaping (_ card: CreditCard?) -> Void) {
        verificationMethod?.verify("12345") { (_, verificationMethod, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(verificationMethod)
            XCTAssertEqual(verificationMethod?.state, .verified)
            
            verificationMethod?.retrieveCreditCard { (creditCard, _) in
                self.waitForActive(creditCard!) { (activeCard) in
                    completion(activeCard)
                }
            }
        }
    }
    
    func makeCreditCardDefault(_ expectation: XCTestExpectation, card: CreditCard?, completion: @escaping (_ defaultCreditCard: CreditCard?) -> Void) {
        card?.makeDefault { (_, defaultCreditCard, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(defaultCreditCard)
            completion(defaultCreditCard)
        }
    }
    
    func waitForActive(_ pendingCard: CreditCard, retries: Int = 0, completion: @escaping (_ activeCard: CreditCard) -> Void) {        
        if pendingCard.state == TokenizationState.active {
            completion(pendingCard)
            return
        }
        
        if pendingCard.state != TokenizationState.pendingActive {
            fail("Cards that aren't in pending active state will not transition to active")
            return
        }
        
        if retries > 20 {
            fail("Exceeded retries waiting for pending active card to transition to active")
            return
        }
        
        let time = DispatchTime.now() + 2
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            pendingCard.getCard { (creditCard, error) in
                guard error == nil else {
                    fail("failed to retrieve credit card will polling for active state")
                    return
                }
                
                self.waitForActive(creditCard!, retries: retries + 1, completion: completion)
            }
        }
    }
    
    func createAcceptVerifyAmExCreditCard(_ expectation: XCTestExpectation, pan: String, user: User?, completion: @escaping (_ creditCard: CreditCard?) -> Void) {
        let address = Address(street1: "Street 1", street2: "Street 2", street3: "Street 3", city: "New York", state: "NY", postalCode: "80302", countryCode: "US")
        let cardInfo = CardInfo(pan: pan, expMonth: 5, expYear: 2020, cvv: "434", name: "John Smith", address: address, riskData: nil)
        
        user?.createCreditCard(cardInfo: cardInfo) { [unowned self] (creditCard, error) in
            XCTAssertNil(error)
            
            self.assertCreditCard(creditCard)
            
            self.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                self.selectVerificationType(expectation, card: card) { (verificationMethod) in
                    self.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (card) in
                        completion(card)
                    }
                }
            }
        }
    }
    
    func deactivateCreditCard(_ expectation: XCTestExpectation, creditCard: CreditCard?, completion: @escaping (_ deactivatedCard: CreditCard?) -> Void) {
        creditCard?.deactivate(causedBy: .cardholder, reason: "lost card") { (_, creditCard, error) in
            XCTAssertNil(error)
            XCTAssertEqual(creditCard?.state, TokenizationState.deactivated)
            completion(creditCard)
        }
    }
    
    class func randomStringWithLength(_ len: Int) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0...(len - 1) {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString as String
    }
    
    class func randomNumbers(_ len: Int = 16) -> String {
        let letters: NSString = "0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0...(len - 1) {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString as String
    }
    
    class func getEmail(random: Bool = false) -> String {
        return random ? "testUser\(Int(Date().timeIntervalSince1970 * 1000))@test.com" : "ms7RsgsX@X5pvb.koWBX"
    }
    
    func randomPan() -> String {
        return "999941111111" + TestHelper.randomNumbers(4)
    }
    
    func generateRandomSeId() -> String {
        if let deviceSecureElementId = MockPaymentDeviceConnector(paymentDevice: PaymentDevice()).deviceInfo()!.secureElement?.secureElementId {
            return deviceSecureElementId
        } else {
            var dateString = String(format: "%2X", UInt64(Date().timeIntervalSince1970))
            while dateString.count < 12 {
                dateString = "0" + dateString
            }
            let secureElementId = "DEADBEEF0000" + "528704504258" +  dateString + "FFFF427208236250082462502041FFFF082562502041FFFF"
            return secureElementId
        }
        
    }
}
