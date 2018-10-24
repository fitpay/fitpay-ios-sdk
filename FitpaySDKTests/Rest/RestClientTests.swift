import XCTest
import Nimble

@testable import FitpaySDK

class RestClientTests: XCTestCase {
    let password = "1029"
    
    var session: RestSession!
    var client: RestClient!
    var testHelper: TestHelper!
    
    let restRequest = MockRestRequest()
    
    override func invokeTest() {
        // stop test on first failure - kind of like jUnit.  Avoid unexpected null references etc
        self.continueAfterFailure = false
        
        super.invokeTest()
        
        // keep running tests in suite
        self.continueAfterFailure = true
    }
    
    override func setUp() {
        super.setUp()
        
        FitpayConfig.clientId = "fp_webapp_pJkVp2Rl"
        FitpayConfig.apiURL = "https://api.fit-pay.com"
        FitpayConfig.authURL = "https://auth.fit-pay.com"
        session = RestSession(restRequest: restRequest)
        client = RestClient(session: session!, restRequest: restRequest)
        testHelper = TestHelper(session: session, client: client)
        client.keyPair = MockSECP256R1KeyPair()
    }
    
    override func tearDown() {
        self.client = nil
        self.session = nil
        super.tearDown()
    }
    
    func testCreateEncryptionKeyCreatesKey() {
        let expectation = super.expectation(description: "'encryptionKey' create key")
        client.createEncryptionKey(clientPublicKey: client.keyPair.publicKey!) { (encryptionKey, error) -> Void in
            
            XCTAssertNil(error)
            XCTAssertNotNil(encryptionKey)
            XCTAssertNotNil(encryptionKey?.keyId)
            XCTAssertNotNil(encryptionKey?.created)
            XCTAssertNotNil(encryptionKey?.createdEpoch)
            XCTAssertNotEqual(encryptionKey?.createdEpoch, 0)
            XCTAssertNotNil(encryptionKey?.serverPublicKey)
            XCTAssertNotNil(encryptionKey?.clientPublicKey)
            XCTAssertNotNil(encryptionKey?.active)
            expectation.fulfill()
        }
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testEncryptionKeyRetrievesKeyWithSameFieldsAsCreated() {
        let expectation = super.expectation(description: "'encryptionKey' retrieves key")
        
        client.createEncryptionKey(clientPublicKey: self.client.keyPair.publicKey!) { [unowned self] (createdEncryptionKey, createdError) -> Void in
            
            self.client.encryptionKey((createdEncryptionKey?.keyId)!) { (retrievedEncryptionKey, _) -> Void in
                
                XCTAssertNil(createdError)
                XCTAssertNotNil(retrievedEncryptionKey)
                XCTAssertNotNil(retrievedEncryptionKey?.keyId)
                XCTAssertNotNil(retrievedEncryptionKey?.created)
                XCTAssertNotNil(retrievedEncryptionKey?.createdEpoch)
                XCTAssertNotEqual(retrievedEncryptionKey?.createdEpoch, 0)
                XCTAssertNotNil(retrievedEncryptionKey?.serverPublicKey)
                XCTAssertNotNil(retrievedEncryptionKey?.clientPublicKey)
                XCTAssertNotNil(retrievedEncryptionKey?.active)
                
                XCTAssertEqual(retrievedEncryptionKey?.keyId, createdEncryptionKey?.keyId)
                XCTAssertEqual(retrievedEncryptionKey?.created, createdEncryptionKey?.created)
                XCTAssertEqual(retrievedEncryptionKey?.createdEpoch, createdEncryptionKey?.createdEpoch)
                XCTAssertEqual(retrievedEncryptionKey?.serverPublicKey, createdEncryptionKey?.serverPublicKey)
                XCTAssertEqual(retrievedEncryptionKey?.clientPublicKey, createdEncryptionKey?.clientPublicKey)
                XCTAssertEqual(retrievedEncryptionKey?.active, createdEncryptionKey?.active)
                
                expectation.fulfill()
            }
            
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeleteEncryptionKeyDeletesCreatedKey() {
        let expectation = self.expectation(description: "'deleteEncryptionKey' deletes key")
        
        client.createEncryptionKey(clientPublicKey: self.client.keyPair.publicKey!) { [unowned self] (createdEncryptionKey, createdError) -> Void in
            XCTAssertNil(createdError)
            XCTAssertNotNil(createdEncryptionKey)
            
            self.client.encryptionKey(createdEncryptionKey!.keyId!) { (retrievedEncryptionKey, retrievedError) -> Void in
                XCTAssertNil(retrievedError)
                
                self.client.deleteEncryptionKey((retrievedEncryptionKey?.keyId)!) { (error) -> Void in
                    XCTAssertNil(error)
                    expectation.fulfill()
                }
            }
            
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserCreate() {
        let expectation = super.expectation(description: "'user' created")
        
        let email = TestHelper.getEmail()
        let pin = "1234"
        
        self.client.createUser(email, password: pin, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil, termsAccepted: nil, origin: nil, originAccountCreated: nil) { (user, error) -> Void in
            XCTAssertNotNil(user, "user is nil")
//            XCTAssertNotNil(user?.created)
//            XCTAssertNotNil(user?.links)
            XCTAssertNotNil(user?.createdEpoch)
            XCTAssertNotNil(user?.encryptedData)
            
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserCreateLoginAndDeleteUser() {
        let expectation = super.expectation(description: "'user' created")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] user in
            self.testHelper.deleteUser(user, expectation: expectation)
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserRetrievesUserById() {
        let expectation = super.expectation(description: "'user' retrieves user by her id")
        
        self.testHelper.createAndLoginUser(expectation) { (user) in
            self.client.user(id: (user?.id)!) { (user, _) -> Void in
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreateCreditCard() {
        let expectation = super.expectation(description: "'creditCards' retrieves credit cards for user")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self](user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, _) in
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUserListCreditCardsListsCreditCardsForUser() {
        let expectation = super.expectation(description: "'listCreditCards' lists credit cards for user")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.getCreditCardsForUser(expectation, user: user) { (user, result) in
                        
                        XCTAssertEqual(creditCard?.creditCardId, result?.results?.first?.creditCardId)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardDeleteDeletesCreditCardAfterCreatingIt() {
        let expectation = super.expectation(description: "'delete' deletes credit card after creating it")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    
                    creditCard?.deleteCard { deleteCardError in
                        XCTAssertNil(deleteCardError)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
        
    func testMakeDefaultMakesCreditCardDefault() {
        let expectation = super.expectation(description: "'makeDefault' makes credit card default")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { card in
                                self.testHelper.createAcceptVerifyAmExCreditCard(expectation, pan: "9999611111111114", user: user) { (creditCard) in
                                    self.testHelper.makeCreditCardDefault(expectation, card: creditCard) { (_) in
                                        self.testHelper.deleteUser(user, expectation: expectation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceCreateWithMinimum() {
        let expectation = super.expectation(description: "device created")
        let deviceType = "WATCH"
        let manufacturerName = "Fitpay"
        let deviceName = "PSPS"
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            let device = Device(deviceType: deviceType, manufacturerName: manufacturerName, deviceName: deviceName, serialNumber: nil,
                                modelNumber: nil, hardwareRevision: nil, firmwareRevision: nil,
                                softwareRevision: nil, notificationToken: nil, systemId: nil, osName: nil,
                                secureElement: nil)
            
            user?.createDevice(device) { (device, error) -> Void in
                XCTAssertNotNil(device)
                XCTAssertNil(error)
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
        
    }
    
    func testDeactivateCreditCard() {
        let expectation = super.expectation(description: "'deactivate' makes credit card deactivated")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                self.testHelper.deactivateCreditCard(expectation, creditCard: verifiedCreditCard) { (_) in
                                    self.testHelper.deleteUser(user, expectation: expectation)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 55, handler: nil)
    }
    
    func testReactivateCreditCardActivatesCard() {
        let expectation = super.expectation(description: "'reactivate' makes credit card activated")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                self.testHelper.deactivateCreditCard(expectation, creditCard: verifiedCreditCard) { (deactivatedCard) in
                                    deactivatedCard?.reactivate(causedBy: .cardholder, reason: "found card") { (_, creditCard, error) in
                                        XCTAssertNil(error)
                                        XCTAssertEqual(creditCard?.state, .active)
                                        
                                        self.testHelper.deleteUser(user, expectation: expectation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardEditAcceptTermsUrl() {
        let expectation = super.expectation(description: "'creditCard' edit accept terms url")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.editAcceptTermsUrlSuccess(creditCard)
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardGetVerificationMethods() {
        let expectation = super.expectation(description: "'creditCard' get verification methods")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (creditCard) in
                        self.testHelper.getVerificationMethods(expectation, card: creditCard) { (_) in
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardDeclineTerms() {
        let expectation = super.expectation(description: "'creditCard' decline terms")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    creditCard?.declineTerms { (_, card, error) in
                        XCTAssertNil(error)
                        XCTAssertEqual(card?.state, .declinedTermsAndConditions)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardVerify() {
        let expectation = super.expectation(description: "'creditCard' verify card with id")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self](user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (_) in
                                self.testHelper.deleteUser(user, expectation: expectation)
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserListDevisesListsDevices() {
        let expectation = super.expectation(description: "test 'device' retrieves devices by user id")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                user?.getDevices(limit: 10, offset: 0) { (result, error) in
                    XCTAssertNil(error)
                    
                    XCTAssertNotNil(result)
                    XCTAssertEqual(result?.results?.count, 1)
                    
                    for deviceInfo in result!.results! {
                        XCTAssertNotNil(deviceInfo.deviceIdentifier)
                        XCTAssertNotNil(deviceInfo.metadata)
                    }
                    
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserCreateNewDeviceCreatesDevice() {
        let expectation = super.expectation(description: "test 'user.createDevice' creates device")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceDelete() {
        let expectation = super.expectation(description: "test 'device.deleteDevice' deletes device")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                user?.getDevices(limit: 10, offset: 0) { (result, error) in
                    XCTAssertNil(error)
                    
                    XCTAssertNotNil(result)
                    XCTAssertEqual(result?.results?.count, 1)
                    
                    let deviceInfo = result!.results!.first!
                    
                    XCTAssertNotNil(deviceInfo.deviceIdentifier)
                    XCTAssertNotNil(deviceInfo.metadata)
                    
                    deviceInfo.deleteDeviceInfo { (error) in
                        XCTAssertNil(error)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceUserRetrievesUser() {
        let expectation = super.expectation(description: "test 'device.user' retrieves user ")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                device?.user { (retrievedUser, error) in
                    XCTAssertNotNil(user)
                    XCTAssertNil(error)
                    
                    self.testHelper.deleteUser(retrievedUser, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceUpdate() {
        let expectation = super.expectation(description: "test 'device' update device")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                expect(device).toNot(beNil())
                device?.firmwareRevision = "2.7.7.7"
                device?.softwareRevision = "6.8.1"

                device?.updateDevice(device!) { (updatedDevice, error) -> Void in
                    expect(error).to(beNil())
                    expect(updatedDevice).toNot(beNil())
                    expect(updatedDevice!.firmwareRevision).to(equal("2.7.7.7"))
                    expect(updatedDevice!.softwareRevision).to(equal("6.8.1"))

                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceRetrievesCommitsFromDevice() {
        let expectation = super.expectation(description: "test 'device' retrieving commits from device")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                user?.getDevices(limit: 10, offset: 0) { (result, error) in
                    XCTAssertNil(error)
                    
                    result?.results?.first?.listCommits(commitsAfter: nil, limit: 10, offset: 0) { (commits, error) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(commits)
                        XCTAssertNotNil(commits?.limit)
                        XCTAssertNotNil(commits?.totalResults)
                        XCTAssertNotNil(commits?.links)
                        XCTAssertNotNil(commits?.results)
                        
                        for commit in commits!.results! {
                            XCTAssertNotNil(commit.commitType)
                            //XCTAssertNotNil(commit.payload)
                            XCTAssertNotNil(commit.commitId)
                        }
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }    
    
    func testAssetsRetrievesAssetWithOptions() {
        let expectation = super.expectation(description: "'assets' retrieves asset")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    user?.getCreditCards(excludeState: [], limit: 1, offset: 0) { (collection, error) in
                        let creditCard: CreditCard = collection!.results![0]
                        creditCard.cardMetaData?.cardBackgroundCombinedEmbossed?.first?.retrieveAssetWith(options: [.width(600), .height(600), .fontBold(false)]) { (asset, error) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(asset?.image)
                            
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                        
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testAssetsRetrievesAsset() {
        let expectation = super.expectation(description: "'assets' retrieves asset")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    creditCard?.cardMetaData?.brandLogo?.first?.retrieveAsset { (asset, error) in
                        XCTAssertNil(error)
                        XCTAssertNotNil(asset?.image)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetIssuers() {
        let expectation = super.expectation(description: "'testGetIssuers' gets issuers")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.client.issuers { (issuers, error) in
                XCTAssertNotNil(issuers, "issuers should not be nil")
                XCTAssertNil(error)
                XCTAssertNotNil(issuers?.countries, "countries should not be nil")
                XCTAssertNotNil(issuers?.countries?["US"])
                
                for country in issuers!.countries! {
                    XCTAssertNotNil(country.value.cardNetworks, "cardNetworks should not be nil")
                    XCTAssertNotEqual(country.value.cardNetworks?.count, 0)
                    
                    for cardNetwork in country.value.cardNetworks! {
                        XCTAssertNotNil(cardNetwork.value.issuers, "issuers should not be nil")
                        XCTAssertNotEqual(cardNetwork.value.issuers?.count, 0)
                    }
                }
                
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testTransactionRetrievesTransactionsByUserId() {
        let expectation = super.expectation(description: "'transaction' retrieves transactions by user id")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, _) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                verifiedCreditCard?.listTransactions(limit: 1, offset: 0) { (transactions, error) -> Void in
                                    
                                    XCTAssertNil(error)
                                    XCTAssertNotNil(transactions)
                                    XCTAssertNotNil(transactions?.limit)
                                    XCTAssertNotNil(transactions?.totalResults)
                                    XCTAssertNotNil(transactions?.links)
                                    XCTAssertNotNil(transactions?.results)
                                    
                                    if let transactionsResults = transactions!.results {
                                        for transactionInfo in transactionsResults {
                                            XCTAssertNotNil(transactionInfo.transactionId)
                                            XCTAssertNotNil(transactionInfo.transactionType)
                                        }
                                        
                                        self.testHelper.deleteUser(user, expectation: expectation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCompareCreatedEpochToCreatedTS() {
        let expectation = super.expectation(description: "'createdEpoch' converted correctly to seconds from ms")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let nsdate = dateFormatter.date(from: user!.created!)
            
            let epochDiff = abs(nsdate!.timeIntervalSince1970 - user!.createdEpoch!)
            
            XCTAssertLessThan(epochDiff, 1, "validate epoch converted correctly")
            
            self.testHelper.deleteUser(user, expectation: expectation)
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
}
