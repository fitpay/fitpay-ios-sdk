import XCTest
@testable import FitpaySDK

class RestClientTests: XCTestCase {
    var clientId = "fp_webapp_pJkVp2Rl"
    let redirectUri = "https://webapp.fit-pay.com"
    let password = "1029"

    var session: RestSession!
    var client: RestClient!
    var testHelper: TestHelper!
    
    override func invokeTest() {
        // stop test on first failure - kind of like jUnit.  Avoid unexpected null references etc
        self.continueAfterFailure = false
        
        super.invokeTest()
        
        // keep running tests in suite
        self.continueAfterFailure = true
    }
    
    override func setUp() {
        super.setUp()

        FitpayConfig.configure(clientId: clientId)
        self.session = RestSession()
        self.client = RestClient(session: self.session!)
        self.testHelper = TestHelper(session: self.session, client: self.client)
    }
    
    override func tearDown() {
        self.client = nil
        self.session = nil
        super.tearDown()
    }
    
    func testCreateEncryptionKeyCreatesKey() {
        let expectation = super.expectation(description: "'createEncryptionKey' creates key")
        
        self.client.createEncryptionKey(clientPublicKey:self.client.keyPair.publicKey!) { (encryptionKey, error) -> Void in
            
            XCTAssertNil(error)
            XCTAssertNotNil(encryptionKey)
            XCTAssertNotNil(encryptionKey?.links)
            XCTAssertNotNil(encryptionKey?.keyId)
            XCTAssertNotNil(encryptionKey?.created)
            XCTAssertNotNil(encryptionKey?.createdEpoch)
            XCTAssertNotEqual(encryptionKey?.createdEpoch, 0)
            XCTAssertNotNil(encryptionKey?.serverPublicKey)
            XCTAssertNotNil(encryptionKey?.clientPublicKey)
            XCTAssertNotNil(encryptionKey?.active)
            XCTAssertNotEqual(encryptionKey?.links?.count, 0)
            
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testEncryptionKeyRetrievesKeyWithSameFieldsAsCreated() {
        let expectation = super.expectation(description: "'encryptionKey' retrieves key")
        
        self.client.createEncryptionKey(clientPublicKey:self.client.keyPair.publicKey!) { [unowned self] (createdEncryptionKey, createdError) -> Void in
            
            self.client.encryptionKey((createdEncryptionKey?.keyId)!) { (retrievedEncryptionKey, retrievedError) -> Void in
                
                XCTAssertNil(createdError)
                XCTAssertNotNil(retrievedEncryptionKey)
                XCTAssertNotNil(retrievedEncryptionKey?.links)
                XCTAssertNotNil(retrievedEncryptionKey?.keyId)
                XCTAssertNotNil(retrievedEncryptionKey?.created)
                XCTAssertNotNil(retrievedEncryptionKey?.createdEpoch)
                XCTAssertNotEqual(retrievedEncryptionKey?.createdEpoch, 0)
                XCTAssertNotNil(retrievedEncryptionKey?.serverPublicKey)
                XCTAssertNotNil(retrievedEncryptionKey?.clientPublicKey)
                XCTAssertNotNil(retrievedEncryptionKey?.active)
                XCTAssertNotEqual(retrievedEncryptionKey?.links?.count, 0)
                
                XCTAssertEqual(retrievedEncryptionKey?.links?.count, createdEncryptionKey?.links?.count)
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
    
    func testEncryptionKeyFailsToRetrieveKeyWithFakeId() {
        let expectation = super.expectation(description: "'encryptionKey' fails to retrieve key with fale id")
        
        self.client.encryptionKey("some_fake_id") { (retrievedEncryptionKey, retrievedError) -> Void in
            
            XCTAssertNotNil(retrievedError)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testDeleteEncryptionKeyDeletesCreatedKey() {
        let expectation = super.expectation(description: "'deleteEncryptionKey' deletes key")
        
        self.client.createEncryptionKey(clientPublicKey:self.client.keyPair.publicKey!) { [unowned self] (createdEncryptionKey, createdError) -> Void in
            XCTAssertNil(createdError)
            XCTAssertNotNil(createdEncryptionKey)
            
            self.client.encryptionKey(createdEncryptionKey!.keyId!) { (retrievedEncryptionKey, retrievedError) -> Void in
                XCTAssertNil(retrievedError)
                
                self.client.deleteEncryptionKey((retrievedEncryptionKey?.keyId)!) { (error) -> Void in
                    XCTAssertNil(error)
                    
                    self.client.encryptionKey((retrievedEncryptionKey?.keyId)!) { (againRetrievedEncryptionKey, againRetrievedError) -> Void in
                        XCTAssertNil(againRetrievedEncryptionKey)
                        XCTAssertNotNil(againRetrievedError)
                        
                        expectation.fulfill()
                    }
                }
            }
            
        }
        
        super.waitForExpectations(timeout: 100, handler: nil)
    }

    func testResetDeviceTasks() {
        let expectation = super.expectation(description: "'resetDeviceTasks' creates key")
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { [unowned self] (user, device) in
                guard let resetUrlString = device?.deviceResetUrl else { XCTAssert(false, "No url."); return }
                guard let resetUrl = URL(string: resetUrlString) else { XCTAssert(false, "Bad url."); return }
                
                sleep(5)  // resetDeviceTasks fails if called to quickly after createDevice

                self.client.resetDeviceTasks(resetUrl) { (resetDeviceResult, error) in
                    XCTAssertNil(error)

                    guard let resetUrlString = resetDeviceResult?.deviceResetUrl else { XCTAssert(false, "No url."); return }
                    guard let resetUrl = URL(string: resetUrlString) else { XCTAssert(false, "Bad url."); return }

                    self.client.resetDeviceStatus(resetUrl) { (resetDeviceResult, error) in
                        XCTAssertNil(error)

                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 20, handler: nil)
    }

    func testUserCreate() {
        let expectation = super.expectation(description: "'user' created")
        
        let email = TestHelper.randomEmail()
        let pin = "1234"
        
        self.client.createUser(email, password: pin, firstName: nil, lastName: nil, birthDate: nil, termsVersion: nil, termsAccepted: nil, origin: nil, originAccountCreated: nil) { (user, error) -> Void in
            XCTAssertNotNil(user, "user is nil")
            XCTAssertNotNil(user?.info)
            XCTAssertNotNil(user?.created)
            XCTAssertNotNil(user?.links)
            XCTAssertNotNil(user?.createdEpoch)
            XCTAssertNotNil(user?.encryptedData)
            XCTAssertNotNil(user?.info?.email)
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
    
    func testUserUpdateUserGetsError400() {
        let expectation = super.expectation(description: "'user.updateUser' gets error 400")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            let firstName = TestHelper.randomStringWithLength(10)
            let lastNname = TestHelper.randomStringWithLength(10)
            
            user?.updateUser(firstName: firstName, lastName: lastNname, birthDate: nil, originAccountCreated: nil, termsAccepted: nil, termsVersion: nil) { (updateUser, updateError) in
                XCTAssertNil(updateUser)
                
                XCTAssertEqual(updateError?.code, 400)
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserRetrievesUserById() {
        let expectation = super.expectation(description: "'user' retrieves user by her id")
        
        self.testHelper.createAndLoginUser(expectation) { (user) in
            self.client.user(id: (user?.id)!) { (user, error) -> Void in
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreateCreditCard() {
        let expectation = super.expectation(description: "'creditCards' retrieves credit cards for user")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self](user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testUserListCreditCardsListsCreditCardsForUser() {
        let expectation = super.expectation(description: "'listCreditCards' lists credit cards for user")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.listCreditCards(expectation, user: user) { (user, result) in
                        
                        XCTAssertEqual(creditCard?.creditCardId, result?.results?.first?.creditCardId)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testCreditCardDeleteDeletesCreditCardAfterCreatingIt() {
        let expectation = super.expectation(description: "'delete' deletes credit card after creating it")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    
                    creditCard?.deleteCreditCard { deleteCardError in
                        XCTAssertNil(deleteCardError)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testUpdateUpdatesCreditCard() {
        let expectation = super.expectation(description: "'update' updates credit card")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                sleep(1)
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    
                    let name = "User\(NSDate().timeIntervalSince1970)"
                    let street1 = "Street1\(NSDate().timeIntervalSince1970)"
                    let street2 = "Street2\(NSDate().timeIntervalSince1970)"
                    let city = "Beverly Hills"
                    
                    let state = "MO"
                    let postCode = "90210"
                    
                    // TODO: Ask why this causes error 400 is passed
                    let countryCode: String? = nil//"US"
                    
                    creditCard?.update(name:name, street1: street1, street2: street2, city: city, state: state, postalCode: postCode, countryCode: countryCode) { (updatedCard, error) -> Void in
                        XCTAssertNil(error)
                        XCTAssertNotNil(updatedCard)
                        
                        self.testHelper.listCreditCards(expectation, user: user) { (user, result) in
                            let currentCard = result?.results?.first
                            
                            if currentCard?.creditCardId == updatedCard?.creditCardId {
                                XCTAssertEqual(updatedCard?.info?.name, name)
                                XCTAssertEqual(updatedCard?.info?.name, currentCard?.info?.name)
                                
                                XCTAssertEqual(updatedCard?.info?.address?.street1, street1)
                                XCTAssertEqual(updatedCard?.info?.address?.street1, currentCard?.info?.address?.street1)
                                
                                XCTAssertEqual(updatedCard?.info?.address?.street2, street2)
                                XCTAssertEqual(updatedCard?.info?.address?.street2, currentCard?.info?.address?.street2)
                                
                                XCTAssertEqual(updatedCard?.info?.address?.city, city)
                                XCTAssertEqual(updatedCard?.info?.address?.city, currentCard?.info?.address?.city)
                                
                                XCTAssertEqual(updatedCard?.info?.address?.state, state)
                                XCTAssertEqual(updatedCard?.info?.address?.state, currentCard?.info?.address?.state)
                                
                                XCTAssertEqual(updatedCard?.info?.address?.postalCode, postCode)
                                XCTAssertEqual(updatedCard?.info?.address?.postalCode, currentCard?.info?.address?.postalCode)
                                
                                //XCTAssertEqual(updatedCard?.info?.address?.countryCode, countryCode)
                                //XCTAssertEqual(updatedCard?.info?.address?.countryCode, currentCard.info?.address?.countryCode)
                                
                                self.testHelper.deleteUser(user, expectation: expectation)
                            }
                            
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testMakeDefaultMakesCreditCardDefault() {
        let expectation = super.expectation(description: "'makeDefault' makes credit card default")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { card in
                                XCTAssertTrue(card!.isDefault!)
                                
                                self.testHelper.createAcceptVerifyAmExCreditCard(expectation, pan: "9999611111111114", user: user) { (creditCard) in
                                    self.testHelper.makeCreditCardDefault(expectation, card: creditCard) { (defaultCreditCard) in
                                        self.testHelper.deleteUser(user, expectation: expectation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 90, handler: nil)
    }
    
    func testDeviceCreateWithMinimum() {
        let expectation = super.expectation(description: "device created")
        let deviceType = "WATCH"
        let manufacturerName = "Fitpay"
        let deviceName = "PSPS"
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            let device = DeviceInfo(deviceType: deviceType, manufacturerName: manufacturerName, deviceName: deviceName, serialNumber: nil,
                                    modelNumber: nil, hardwareRevision: nil, firmwareRevision: nil,
                                    softwareRevision: nil, notificationToken: nil, systemId: nil, osName: nil,
                                    secureElementId: nil, casd: nil)
            
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
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                self.testHelper.deactivateCreditCard(expectation, creditCard: verifiedCreditCard) { (deactivatedCard) in
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
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                self.testHelper.deactivateCreditCard(expectation, creditCard: verifiedCreditCard) { (deactivatedCard) in
                                    
                                    deactivatedCard?.reactivate(causedBy: .cardholder, reason: "found card") { (pending, creditCard, error) in
                                        XCTAssertNil(error)
                                        XCTAssertEqual(creditCard?.state, .ACTIVE)
                                        
                                        self.testHelper.deleteUser(user, expectation: expectation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        super.waitForExpectations(timeout: 65, handler: nil)
    }
    
    func testCreditCardEditAcceptTermsUrl() {
        let expectation = super.expectation(description: "'creditCard' edit accept terms url")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.editAcceptTermsUrlSuccess(creditCard)
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }

    func testCreditCardGetVerificationMethods() {
        let expectation = super.expectation(description: "'creditCard' get verification methods")

        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (creditCard) in
                        self.testHelper.getVerificationMethods(expectation, card: creditCard) { (verificationMethod) in
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testCreditCardDeclineTerms() {
        let expectation = super.expectation(description: "'creditCard' decline terms")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    creditCard?.declineTerms { (pending, card, error) in
                        XCTAssertNil(error)
                        XCTAssertEqual(card?.state, .DECLINED_TERMS_AND_CONDITIONS)
                        
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
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                self.testHelper.deleteUser(user, expectation: expectation)
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 35, handler: nil)
    }
    
    func testUserListDevisesListsDevices() {
        let expectation = super.expectation(description: "test 'device' retrieves devices by user id")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                user?.listDevices(limit: 10, offset: 0) { (result, error) in
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
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceDelete() {
        let expectation = super.expectation(description: "test 'device.deleteDevice' deletes device")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                user?.listDevices(limit: 10, offset: 0) { (result, error) in
                    XCTAssertNil(error)
                    
                    XCTAssertNotNil(result)
                    XCTAssertEqual(result?.results?.count, 1)
                    
                    let deviceInfo = result!.results!.first!
                    
                    XCTAssertNotNil(deviceInfo.deviceIdentifier)
                    XCTAssertNotNil(deviceInfo.metadata)
                    
                    deviceInfo.deleteDeviceInfo { (error) in
                        XCTAssertNil(error)
                        
                        user?.listDevices(limit: 10, offset: 0) { (result, error) in
                            XCTAssertNil(error)
                            
                            XCTAssertEqual(result?.totalResults, 0)
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
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
                
                let firmwareRev = "2.7.7.7"
                let softwareRev = "6.8.1"
                device?.update(firmwareRev, softwareRevision: softwareRev, notifcationToken: nil) { (updatedDevice, error) -> Void in
                    XCTAssertNil(error)
                    XCTAssertNotNil(updatedDevice)
                    XCTAssertEqual(updatedDevice!.softwareRevision!, softwareRev)
                    XCTAssertEqual(updatedDevice!.firmwareRevision!, firmwareRev)
                    
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceRetrievesCommitsFromDevice() {
        let expectation = super.expectation(description: "test 'device' retrieving commits from device")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                user?.listDevices(limit: 10, offset: 0) { (result, error) in
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
                            XCTAssertNotNil(commit.payload)
                            XCTAssertNotNil(commit.commit)
                        }
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testRelationshipsCreatesAndDeletesRelationship() {
        let expectation = super.expectation(description: "test 'relationships' creates and deletes relationship")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    user?.createRelationship(creditCardId: creditCard!.creditCardId!, deviceId: device!.deviceIdentifier!) { (relationship, error) -> Void in
                        XCTAssertNil(error)
                        XCTAssertNotNil(device)
                        XCTAssertNotNil(relationship?.device)
                        XCTAssertNotNil(relationship?.card)
                        
                        relationship?.deleteRelationship { (error) in
                            XCTAssertNil(error)
                            
                            device?.deleteDeviceInfo { (error) -> Void in
                                XCTAssertNil(error)
                                self.testHelper.deleteUser(user, expectation: expectation)
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testAssetsRetrievesAssetWithOptions() {
        let expectation = super.expectation(description: "'assets' retrieves asset")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    user?.listCreditCards(excludeState: [], limit: 1, offset: 0) { (collection, error) in
                        let creditCard: CreditCard = (collection?.results?[0])!
                        creditCard.cardMetaData?.cardBackgroundCombinedEmbossed?.first?.retrieveAssetWith(options: [.width(600), .height(600), .fontBold(false)]) { (asset, error) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(asset?.image)
                            
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                        
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testAssetsRetrievesAsset() {
        let expectation = super.expectation(description: "'assets' retrieves asset")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    creditCard?.cardMetaData?.brandLogo?.first?.retrieveAsset() { (asset, error) in
                        XCTAssertNil(error)
                        XCTAssertNotNil(asset?.image)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testGetIssuers() {
        let expectation = super.expectation(description: "'testGetIssuers' gets issuers")
        
        self.testHelper.createAndLoginUser(expectation) { [unowned self] (user) in
            self.client.issuers() { (issuers, error) in
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
            self.testHelper.createDevice(expectation, user: user) { (user, device) in
                sleep(1)
                self.testHelper.createCreditCard(expectation, user: user) { (user, creditCard) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard) { (card) in
                        self.testHelper.selectVerificationType(expectation, card: card) { (verificationMethod) in
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod) { (verifiedCreditCard) in
                                verifiedCreditCard?.listTransactions(limit: 1, offset:0) { (transactions, error) -> Void in
                                    
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
        
        super.waitForExpectations(timeout: 50, handler: nil)
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
