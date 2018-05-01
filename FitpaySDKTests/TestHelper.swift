import XCTest
@testable import FitpaySDK

class TestHelper {
    
    let clientId: String!
    let redirectUri: String!
    var session: RestSession!
    var client: RestClient!
    
    init(clientId: String, redirectUri: String, session: RestSession, client: RestClient) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.session = session
        self.client = client
    }
    
    func userValid(_ user: User) {
        XCTAssertNotNil(user.info)
        XCTAssertNotNil(user.created)
        XCTAssertNotNil(user.links)
        XCTAssertNotNil(user.createdEpoch)
        XCTAssertNotNil(user.encryptedData)
        XCTAssertNotNil(user.info?.email)
    }
    
    func createUser(_ expectation:XCTestExpectation, email: String, pin: String, completion: @escaping (User?) -> Void) {
        let currentTime = Date().timeIntervalSince1970 //double or NSTimeInterval
        
        self.client.createUser(email, password: pin, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil,
            termsAccepted: nil, origin: nil, originAccountCreated: nil, clientId: clientId!) { [unowned self] (user, error) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
                debugPrint("created user: \(String(describing: user?.info?.email))")
                if (user != nil) { self.userValid(user!) }
                
                //additional sanity checks that we created a meaningful user
                //PLAT-1388 has a bug on the number of links returned when creating a user. When that gets fixed, reenable this.
                //XCTAssertEqual(user!.links!.count, 4, "Expect the number of links to be at least user, cards, devices") //could change. I'm violating HATEAOS
                
                //because there is such a thing as system clock variance (and I demonstrated it to Jakub), we check +/- 5 minutes.
                let comparisonTime = currentTime - (150) //2.5 minutes.
                let actualTime = user!.createdEpoch! //PGR-551 bug. Drop the /1000.0 when the bug is fixed.
                debugPrint("actualTime created: \(actualTime), expected Time: \(currentTime)")
                XCTAssertGreaterThan(actualTime, comparisonTime, "Want it to be created after the last 2.5 minutes")
                XCTAssertLessThan(actualTime, comparisonTime+300, "Want it to be created no more than the last 2.5 min")
                XCTAssertEqual(user?.email, email, "Want the emails to match up")
                
                completion(user)
        }
        
    }
    
    func createAndLoginUser(_ expectation: XCTestExpectation, email: String = TestHelper.randomEmail(), pin: String = "1234", completion: @escaping (User?) -> Void) {
        createUser(expectation, email: email, pin: pin) { (user) in
            self.session.login(username: email, password: pin) { (loginError) -> Void in
                XCTAssertNil(loginError)
                debugPrint("user isAuthorized: \(self.session.isAuthorized)")
                XCTAssertTrue(self.session.isAuthorized, "user should be authorized")
                
                self.client.user(id: self.session.userId!) { (user, userError) in
                    
                    XCTAssertNotNil(user)
                    if (user != nil) { self.userValid(user!) }
                    XCTAssertEqual(user?.email, email, "Want emails to match up after logging in")
                    
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
    
    func createDevice(_ expectation: XCTestExpectation, user: User?, completion: @escaping (_ user: User?, _ device: DeviceInfo?) -> Void) {
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
        let osName = "ANDROID"
        let secureElementId = self.generateRandomSeId()
        let casd = "7F2182027F7F2181DD9310043A377B2F41800171180052079414524207637093010000295F2001009501825F2404211704044501005308C4D82BA9320F14895F3781809D80F9284A961F10E30DC4296719691C37D77C6CBC488E61DAE99EABDBC6A2ED5BD728CAA71660C0C166438E175F823631976E4389F66D993D6B85541A1ED6034AD9CF51EFA9175BFD75B3EEE14209B35BC2E04CC2C92CF21C9CAB7E842727A198AA5978C230D2FFCA6B868C7E3F35415D9B3B3F0B2AE0ED3786467A8F56B6F15F38207963228E4CE54045E7B09583B81D9D7F3C47DBD1A541987B89C3EFFF058E26357F2181DD9310043A377B2F41800171180052079414524207637093010000295F2001009501885F2404211704044501005308C4D82BA9320F14895F3781800E2A33B14CDDB0DF95CBE5C4E0C3173555379C2B41B287B03848D703ED0C903AEF57E2E1FCD8B80E433FA82D0D8D22EC6AEADB5D9FF416288995C68E5E23AC1C50519C1A70EE37691CC616D21F58E292EACC9209B78FEBA6287A5A7834B410005D2F46F45B67047F6A5DFB8143453D1785CDF7D5184DBC877A91F774443C6D0D5F382072CAC0B3D5E23BD820CC057079FFA10EBBEDE961EC05F8E1F8F2CE4CE45741CB7F2181B99310043A377B2F41800171180052079414524207637093010000305F200100950200805F2404211704044501007F4946B04104CEA4915D70859D8C79884CBC6A30287D9E5D9A6A0694F0A69D41B6ACFC5A1DBC76F1A6FD629504111468F98FBD5C4281478FB3A50A492C07624B2839DAC45846F001005F374066FEB7590CEA9ADAA848059252E407D53CD59C8FC0009992E189A846BBB6A8151318A1ACC6CD61FBC1E4295160DB0784C36ED0ACAA248879CF4AFB0EFEB8409A"
        
        let device = DeviceInfo(deviceType: deviceType, manufacturerName: manufacturerName, deviceName: deviceName, serialNumber: serialNumber,
                                modelNumber: modelNumber, hardwareRevision: hardwareRevision, firmwareRevision: firmwareRevision,
                                softwareRevision: softwareRevision, notificationToken: notificationToken, systemId: systemId, osName: osName,
                                secureElementId: secureElementId, casd: casd)
        
        user?.createDevice(device) { (device, error) -> Void in
            XCTAssertNotNil(device)
            XCTAssertNil(error)
            completion(user, device)
        }
    }
    
    func assetCreditCard(_ card: CreditCard?) {
        XCTAssertNotNil(card?.links)
        XCTAssertNotNil(card?.creditCardId)
        XCTAssertNotNil(card?.userId)
        XCTAssertNotNil(card?.isDefault)
        XCTAssertNotNil(card?.created)
        XCTAssertNotNil(card?.createdEpoch)
        XCTAssertNotNil(card?.state)
        XCTAssertNotNil(card?.cardType)
        XCTAssertNotNil(card?.cardMetaData)
        XCTAssertNotNil(card?.deviceRelationships)
        XCTAssertNotEqual(card?.deviceRelationships?.count, 0)
        XCTAssertNotNil(card?.encryptedData)
        XCTAssertNotNil(card?.info)
        XCTAssertNotNil(card?.info?.address)
        XCTAssertNotNil(card?.info?.cvv)
        XCTAssertNotNil(card?.info?.expMonth)
        XCTAssertNotNil(card?.info?.expYear)
        XCTAssertNotNil(card?.info?.pan)
    }
    
    func createEricCard(_ expectation: XCTestExpectation, pan: String, expMonth: Int, expYear: Int, user: User?, completion:@escaping (_ user: User?, _ creditCard: CreditCard?) -> Void) {
        user?.createCreditCard(
            pan: pan, expMonth: expMonth, expYear: expYear, cvv: "1234", name: "Eric Peers", street1: "4883 Dakota Blvd.",
            street2: "Ste. #209-A", street3: "underneath a bird's nest", city: "Boulder", state: "CO", postalCode: "80304-1111", country: "USA"
        ) { [unowned self](card, error) -> Void in
            debugPrint("creating credit card with \(pan)")
            self.assetCreditCard(card)
            
            XCTAssertNil(error)
            if card?.state == .PENDING_ACTIVE {
                self.waitForActive(card!) { (activeCard) in
                    completion(user, activeCard)
                }
            } else {
                completion(user, card)
            }
        }
    }
    
    func createCreditCard(_ expectation: XCTestExpectation, user: User?, completion: @escaping (_ user: User?, _ creditCard: CreditCard?) -> Void) {
        user?.createCreditCard(pan: "9999405454540004", expMonth: 10, expYear: 2018, cvv: "133", name: "TEST CARD", street1: "1035 Pearl St",
            street2: "Street 2", street3: "Street 3", city: "Boulder", state: "CO", postalCode: "80302", country: "US"
        ) { [unowned self] (card, error) -> Void in
            
            self.assetCreditCard(card)
            XCTAssertNil(error)

            if card?.state == .PENDING_ACTIVE {
                self.waitForActive(card!) { (activeCard) in
                    completion(user, activeCard)
                }
            } else {
                completion(user, card)
            }
        }
    }
    
    func listCreditCards(_ expectation: XCTestExpectation, user: User?, completion: @escaping (_ user: User?, _ result: ResultCollection<CreditCard>?) -> Void) {
        user?.listCreditCards(excludeState:[], limit: 10, offset: 0) { [unowned self] (result, error) -> Void in
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
                    self.assetCreditCard(card)
                }
            }
            
            completion(user, result)
        }
    }
    
    func acceptTermsForCreditCard(_ expectation: XCTestExpectation, card: CreditCard?, completion:@escaping (_ card: CreditCard?) -> Void) {
        debugPrint("acceptingTerms for card: \(String(describing: card))")
        card?.acceptTerms { (pending, acceptedCard, error) in
            
            XCTAssertNil(error)
            XCTAssertNotNil(acceptedCard)
            
            if acceptedCard?.state != .PENDING_VERIFICATION {
                if acceptedCard?.state != .PENDING_ACTIVE {
                    XCTFail("Need to have a pending verification or active after accepting terms")
                }
            }
            
            debugPrint("acceptingTerms done")
            
            if acceptedCard?.state == .PENDING_ACTIVE {
                self.waitForActive(acceptedCard!) { (activeCard) in
                    completion(activeCard)
                }
            } else {
                completion(acceptedCard)
            }
        }
    }
    
    func editAcceptTermsUrlSuccess(_ card: CreditCard?){
        let randomText = TestHelper.randomStringWithLength(10)
        
        //update acceptTerms url
        do {
            try card?.setAcceptTermsUrl(acceptTermsUrl: randomText)
            
            //get acceptTerms url
            let acceptTermsUrl = card?.getAcceptTermsUrl()
            XCTAssertEqual(acceptTermsUrl, randomText)
            
        } catch AcceptTermsError.NoTerms(let errorMessage) {
            XCTFail(errorMessage)
        } catch {
            XCTFail("some error")
        }
    }
    
    func selectVerificationType(_ expectation: XCTestExpectation, card: CreditCard?, completion: @escaping (_ verificationMethod: VerificationMethod?) -> Void) {
        let verificationMethod = card?.verificationMethods?.first
        
        verificationMethod?.selectVerificationType { (pending, verificationMethod, error) in
            XCTAssertNotNil(verificationMethod)
            XCTAssertEqual(verificationMethod?.state, .AWAITING_VERIFICATION)
            XCTAssertNil(error)
            
            completion(verificationMethod)
        }
    }
    
    func verifyCreditCard(_ expectation: XCTestExpectation, verificationMethod: VerificationMethod?, completion: @escaping (_ card: CreditCard?) -> Void) {
        verificationMethod?.verify("12345") { (pending, verificationMethod, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(verificationMethod)
            XCTAssertEqual(verificationMethod?.state, .VERIFIED)
            
            verificationMethod?.retrieveCreditCard { (creditCard, error) in
                self.waitForActive(creditCard!, completion: { (activeCard) in
                    completion(activeCard)
                })
            }
        }
    }
    
    func makeCreditCardDefault(_ expectation: XCTestExpectation, card: CreditCard?, completion: @escaping (_ defaultCreditCard: CreditCard?) -> Void) {
        card?.makeDefault { (pending, defaultCreditCard, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(defaultCreditCard)
            XCTAssertTrue(defaultCreditCard!.isDefault!)
            completion(defaultCreditCard)
        }
    }
    
    func waitForActive(_ pendingCard: CreditCard, retries: Int = 0, completion: @escaping (_ activeCard: CreditCard) -> Void) {
        debugPrint("pending card state is \(String(describing: pendingCard.state))")
        
        if pendingCard.state == TokenizationState.ACTIVE {
            completion(pendingCard)
            return
        }
        
        if pendingCard.state != TokenizationState.PENDING_ACTIVE {
            XCTFail("Cards that aren't in pending active state will not transition to active")
            return
        }
        
        if retries > 20 {
            XCTFail("Exceeded retries waiting for pending active card to transition to active")
            return
        }
        
        let time = DispatchTime.now() + 2
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            
            pendingCard.getCreditCard() { (creditCard, error) in
                guard error == nil else {
                    XCTFail("failed to retrieve credit card will polling for active state")
                    return
                }
                
                self.waitForActive(creditCard!, retries: retries + 1, completion: completion)
            }
        }
    }
    
    func createAcceptVerifyAmExCreditCard(_ expectation: XCTestExpectation, pan: String, user: User?, completion: @escaping (_ creditCard: CreditCard?) -> Void) {
        user?.createCreditCard(pan: pan, expMonth: 5, expYear: 2020, cvv: "434", name: "John Smith", street1: "Street 1", street2: "Street 2",
            street3: "Street 3", city: "New York", state: "NY", postalCode: "80302", country: "USA") { [unowned self] (creditCard, error) in
            
            XCTAssertNil(error)
            
            self.assetCreditCard(creditCard)
            
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
        debugPrint("deactivateCreditCard")
        creditCard?.deactivate(causedBy: .CARDHOLDER, reason: "lost card") { (pending, creditCard, error) in
            XCTAssertNil(error)
            XCTAssertEqual(creditCard?.state, TokenizationState.DEACTIVATED)
            completion(creditCard)
        }
    }
    
    class func randomStringWithLength (_ len: Int) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0...(len - 1) {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString as String
    }
    
    class func randomNumbers (_ len: Int = 16) -> String {
        let letters: NSString = "0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0...(len - 1) {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString as String
    }
    
    class func randomEmail() -> String {
        let email = (((randomStringWithLength(8) + "@") + randomStringWithLength(5)) + ".") + randomStringWithLength(5)
        
        return email
    }
    
    func randomPan() -> String {
        return "999941111111" + TestHelper.randomNumbers(4)
    }
    
    func generateRandomSeId() -> String {
        return MockPaymentDeviceConnector(paymentDevice: PaymentDevice()).deviceInfo()!.secureElementId ?? ""
    }
}
