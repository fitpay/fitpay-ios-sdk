
import XCTest
@testable import FitpaySDK

class RestClientTests: XCTestCase
{
    var clientId = "fp_webapp_pJkVp2Rl"
    let redirectUri = "https://webapp.fit-pay.com"
    let password = "1029"

    var session:RestSession!
    var client:RestClient!
    var testHelper:TestHelpers!
    
    override func invokeTest()
    {
        // stop test on first failure - kind of like jUnit.  Avoid unexpected null references etc
        self.continueAfterFailure = false;
        
        super.invokeTest();
        
        // keep running tests in suite
        self.continueAfterFailure = true;

    }

    override func setUp()
    {
        super.setUp()
        let config = FitpaySDKConfiguration(clientId:"pagare", redirectUri:"https://demo-qa.pagare.me", baseAuthURL: "https://demo-qa.pagare.me", baseAPIURL: "https://demo-qa.pagare.me/api")
        if let error = config.loadEnvironmentVariables() {
            print("Can't load config from environment. Error: \(error)")
        } else {
            clientId = config.clientId
        }
        
        self.session = RestSession(configuration: config)
        self.client = RestClient(session: self.session!)
        self.testHelper = TestHelpers(clientId: clientId, redirectUri: redirectUri, session: self.session, client: self.client)
    }
    
    override func tearDown()
    {
        self.client = nil
        self.session = nil
        super.tearDown()
    }

    func testCreateEncryptionKeyCreatesKey()
    {
        let expectation = super.expectation(description: "'createEncryptionKey' creates key")
        
        self.client.createEncryptionKey(clientPublicKey:self.client.keyPair.publicKey!, completion: { (encryptionKey, error) -> Void in

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
        })
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }

    func testEncryptionKeyRetrievesKeyWithSameFieldsAsCreated()
    {
        let expectation = super.expectation(description: "'encryptionKey' retrieves key")

        self.client.createEncryptionKey(clientPublicKey:self.client.keyPair.publicKey!, completion:
        {
            [unowned self](createdEncryptionKey, createdError) -> Void in

            self.client.encryptionKey((createdEncryptionKey?.keyId)!, completion:
            {
                (retrievedEncryptionKey, retrievedError) -> Void in
                
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
            })

        })

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testEncryptionKeyFailsToRetrieveKeyWithFakeId()
    {
        let expectation = super.expectation(description: "'encryptionKey' fails to retrieve key with fale id")
        
        self.client.encryptionKey("some_fake_id", completion:
        {
                (retrievedEncryptionKey, retrievedError) -> Void in
                
                XCTAssertNotNil(retrievedError)
                expectation.fulfill()
        })
        
        super.waitForExpectations(timeout: 100, handler: nil)
    }

    func testDeleteEncryptionKeyDeletesCreatedKey()
    {
        let expectation = super.expectation(description: "'deleteEncryptionKey' deletes key")

        self.client.createEncryptionKey(clientPublicKey:self.client.keyPair.publicKey!, completion:
        {
            [unowned self](createdEncryptionKey, createdError) -> Void in
            
            XCTAssertNil(createdError)
            XCTAssertNotNil(createdEncryptionKey)
            
            if createdError != nil
            {
                expectation.fulfill()
                return
            }
            
            self.client.encryptionKey(createdEncryptionKey!.keyId!, completion:
            {
                (retrievedEncryptionKey, retrievedError) -> Void in
                
                XCTAssertNil(retrievedError)
                if retrievedError != nil
                {
                    expectation.fulfill()
                    return
                }
                
                self.client.deleteEncryptionKey((retrievedEncryptionKey?.keyId)!, completion:
                {
                    (error) -> Void in
                    
                    XCTAssertNil(error)
                    
                    if error != nil
                    {
                        expectation.fulfill()
                        return
                    }
                    
                    self.client.encryptionKey((retrievedEncryptionKey?.keyId)!, completion:
                    {
                        (againRetrievedEncryptionKey, againRetrievedError) -> Void in
                        
                        XCTAssertNil(againRetrievedEncryptionKey)
                        XCTAssertNotNil(againRetrievedError)
                    
                        expectation.fulfill()
                    })
                })
            })
            
        })

        super.waitForExpectations(timeout: 100, handler: nil)
    }
 
    func testUserCreate()
    {
        let expectation = super.expectation(description: "'user' created")
        
        let email = self.testHelper.randomEmail()
        let pin = "1234"
        
        self.client.createUser(
            email, password: pin, firstName:nil, lastName:nil, birthDate:nil,
            termsVersion:nil, termsAccepted:nil, origin:nil, originAccountCreated:nil,
            clientId:clientId ,completion:
        {
            (user, error) -> Void in
            
            XCTAssertNotNil(user, "user is nil")
            XCTAssertNotNil(user?.info)
            XCTAssertNotNil(user?.created)
            XCTAssertNotNil(user?.links)
            XCTAssertNotNil(user?.createdEpoch)
            XCTAssertNotNil(user?.encryptedData)
            XCTAssertNotNil(user?.info?.email)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    
    func testUserCreateAndLogin()
    {
        let expectation = super.expectation(description: "'user' created")
        
        self.testHelper.createAndLoginUser(expectation)
        {
           [unowned self] user in
            self.testHelper.deleteUser(user, expectation: expectation)
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    //this tries to populate all the optional fields and check they are set. - PLAT-1414
/*    func testUserCreateOptionalFields() {
        let expectation = super.expectationWithDescription("create a user with optional fields")
//        let currentTime = NSDate() //double or NSTimeInterval
        let email = self.testHelper.randomEmail()

        self.client.createUser(email, password: "5147", firstName:"Bartholomew", lastName:"Cubbins Oobleck",
                               birthDate:"1/1/1949",
                               termsVersion:"2.3", termsAccepted:"2014-1-31T15:15:13.123Z",
                               origin: "Eric's little Startup", originAccountCreated:"2013-1-31T10:11:12.133Z",
                               completion:
            {
                (user, error) -> Void in
                self.testHelper.userValid(user!)
                XCTAssertEqual(user!.info!.email!, email)
                XCTAssertEqual(user!.info!.firstName!, "Bartholomew")
                XCTAssertEqual(user!.info!.lastName!, "Cubbins Oobleck")
                XCTAssertEqual(user!.info!.birthDate!, "1/1/1949")
                //XCTAssertEqual(user!.termsVersion!, "2.3")
                //XCTAssertEqual(user!.termsAccepted!, "2014-1-31T15:15:13.123Z")
                //XCTAssertEqual(user!.originAccountCreated!, "2013-1-31T10:11:12.133Z")
                expectation.fulfill()
        })
        super.waitForExpectationsWithTimeout(10, handler: nil)
        
    }
  */  
    func testUserDeleteUserDeletesUser()
    {
        let expectation = super.expectation(description: "'user.deleteUser' deletes user")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self] user in
            self.testHelper.deleteUser(user, expectation: expectation)
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserUpdateUserGetsError400()
    {
        let expectation = super.expectation(description: "'user.updateUser' gets error 400")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self] (user) in
            
            let firstName = self.testHelper.randomStringWithLength(10)
            let lastNname = self.testHelper.randomStringWithLength(10)
            
            user?.updateUser(firstName: firstName, lastName: lastNname, birthDate: nil, originAccountCreated: nil, termsAccepted: nil, termsVersion: nil)
            {
                updateUser, updateError in
                XCTAssertNil(updateUser)
                //XCTAssertEqual(updateUser?.firstName, firstName)
                //XCTAssertEqual(updateUser?.lastName, lastNname)
                
                XCTAssertEqual(updateError?.code, 400)
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }

    func testUserRetrievesUserById()
    {
        let expectation = super.expectation(description: "'user' retrieves user by her id")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            (user) in
            self.client.user(id: (user?.id)!, completion:
            {
                (user, error) -> Void in
                self.testHelper.deleteUser(user, expectation: expectation)
            })
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreateCreditCard()
    {
        let expectation = super.expectation(description: "'creditCards' retrieves credit cards for user")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }

        super.waitForExpectations(timeout: 15, handler: nil)
    }
    /* disabled due to PLAT-1404, PLAT-1406
     
    //we need to decrypt the payloads that respond with PII info. Check that the full data suite was sent/comes back.
    func testCardCreateCheckReturn() {
        let expectation = super.expectationWithDescription("create a card and decrypt the data coming back")
        
        self.testHelper.createAndLoginUser(expectation) {
            user in
            self.testHelper.createDevice(expectation, user: user) {
                (user, device) in
                self.testHelper.createEricCard(expectation, pan: "9999555566664321", expMonth: 3, expYear: 2019, user: user) {
                    (user, card) in
                    
                    //            pan: pan, expMonth: expMonth, expYear: expYear, cvv: "1234", name: "Eric Peers", street1: "4883 Dakota Blvd.",
                    // street2: "", street3: "", city: "Boulder", state: "CO", postalCode: "80304-1111", country: "USA"
                    XCTAssertEqual(card?.info?.pan, "############4321", "Look for unmasked last 4")
                    XCTAssertEqual(card?.info?.cvv, "####", "Look for masked cvv")
                    XCTAssertEqual(card?.info?.expYear, 2019)
                    XCTAssertEqual(card?.info?.expMonth, 3)
                    XCTAssertEqual(card?.info?.name, "Eric Peers")
                    XCTAssertEqual(card?.info?.address?.street1, "4883 Dakota Blvd.")
                    XCTAssertEqual(card?.info?.address?.street2, "Ste. #209-A")
                    XCTAssertEqual(card?.info?.address?.street3, "underneath a bird's nest")
                    XCTAssertEqual(card?.info?.address?.city, "Boulder")
                    XCTAssertEqual(card?.info?.address?.state, "CO")
                    XCTAssertEqual(card?.info?.address?.postalCode, "80304-1111")
                    XCTAssertEqual(card?.info?.address?.countryCode, "USA")
                    self.testHelper.acceptTermsForCreditCard(expectation, card:card) {
                        card in
                        XCTAssertEqual(card?.info?.pan, "############4321", "Look for unmasked last 4")
                        XCTAssertEqual(card?.info?.cvv, "####", "Look for masked cvv")
                        XCTAssertEqual(card?.info?.name, "Eric Peers")
                        XCTAssertEqual(card?.info?.address?.street1, "4883 Dakota Blvd.")
                        XCTAssertEqual(card?.info?.address?.street2, "Ste. #209-A")
                        XCTAssertEqual(card?.info?.address?.street3, "underneath a bird's nest")
                        XCTAssertEqual(card?.info?.address?.city, "Boulder")
                        XCTAssertEqual(card?.info?.address?.state, "CO")
                        XCTAssertEqual(card?.info?.address?.postalCode, "80304-1111")
//                        XCTAssertEqual(card?.info?.address?.countryCode, "USA")
                        XCTAssertEqual(card?.info?.expYear, 2019)
                        XCTAssertEqual(card?.info?.expMonth, 3)
                       
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                    
                }
            }
        }
        super.waitForExpectationsWithTimeout(20, handler: nil)

    }
    */
    func testUserListCreditCardsListsCreditCardsForUser()
    {
        let expectation = super.expectation(description: "'listCreditCards' lists credit cards for user")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    self.testHelper.listCreditCards(expectation, user: user)
                    {
                        (user, result) in
                        
                        XCTAssertEqual(creditCard?.creditCardId, result?.results?.first?.creditCardId)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardDeleteDeletesCreditCardAfterCreatingIt()
    {
        let expectation = super.expectation(description: "'delete' deletes credit card after creating it")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    creditCard?.deleteCreditCard
                    {
                        (deleteCardError) in
                        XCTAssertNil(deleteCardError)
                        
                        if deleteCardError != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
       
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUpdateUpdatesCreditCard()
    {
        let expectation = super.expectation(description: "'update' updates credit card")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    let name:String? = "User\(NSDate().timeIntervalSince1970)"
                    let street1:String? = "Street1\(NSDate().timeIntervalSince1970)"
                    let street2:String? = "Street2\(NSDate().timeIntervalSince1970)"
                    let city:String? = "Beverly Hills"
                    
                    let state = "MO"
                    let postCode:String? = "90210"
                    
                    // TODO: Ask why this causes error 400 is passed
                    let countryCode:String? = nil//"USA"
                    
                    creditCard?.update(name:name, street1: street1, street2: street2, city: city, state: state, postalCode: postCode, countryCode: countryCode, completion:
                    {
                        (updatedCard, error) -> Void in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(updatedCard)
                        
                        self.testHelper.listCreditCards(expectation, user: user)
                        {
                            (user, result) in
                            let currentCard = result?.results?.first
                            
                            if currentCard?.creditCardId == updatedCard?.creditCardId
                            {
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
                    })
                }
            }
        }

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMakeDefaultMakesCreditCardDefault()
    {
        let expectation = super.expectation(description: "'makeDefault' makes credit card default")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard)
                    {
                        (card) in
                        self.testHelper.selectVerificationType(expectation, card: card)
                        {
                            (verificationMethod) in
                            
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod)
                            {
                                card in
                                XCTAssertTrue(card!.isDefault!)

                                self.testHelper.createAcceptVerifyAmExCreditCard(expectation, pan: "9999611111111114", user: user)
                                {
                                    (creditCard) in
                                    
                                    self.testHelper.makeCreditCardDefault(expectation, card: creditCard)
                                    {
                                        (defaultCreditCard) in
                                        self.testHelper.deleteUser(user, expectation: expectation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testDeactivateCreditCard()
    {
        let expectation = super.expectation(description: "'deactivate' makes credit card deactivated")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard)
                    {
                        (card) in
                        self.testHelper.selectVerificationType(expectation, card: card)
                        {
                            (verificationMethod) in
                            
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod)
                            {
                                (verifiedCreditCard) in
                                
                                self.testHelper.deactivateCreditCard(expectation, creditCard: verifiedCreditCard)
                                {
                                    (deactivatedCard) in
                                 
                                    self.testHelper.deleteUser(user, expectation: expectation)
                                }
                            }
                        }
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testReactivateCreditCardActivatesCard()
    {
        let expectation = super.expectation(description: "'reactivate' makes credit card activated")
        
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard)
                    {
                        (card) in
                        self.testHelper.selectVerificationType(expectation, card: card)
                        {
                            (verificationMethod) in
                            
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod)
                            {
                                (verifiedCreditCard) in
                                
                                self.testHelper.deactivateCreditCard(expectation, creditCard: verifiedCreditCard)
                                {
                                    (deactivatedCard) in
                                    
                                    deactivatedCard?.reactivate(causedBy: .CARDHOLDER, reason: "found card")
                                    {
                                        (pending, creditCard, error) in
                                        XCTAssertNil(error)
                                        if error != nil
                                        {
                                            expectation.fulfill()
                                            return
                                        }
                                        
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

        
        super.waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testCreditCardAcceptTerms()
    {
        let expectation = super.expectation(description: "'creditCard' accept terms")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard)
                    {
                        (card) in
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    
    func testCreditCardDeclineTerms()
    {
        let expectation = super.expectation(description: "'creditCard' decline terms")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    creditCard?.declineTerms
                    {
                        (pending, card, error) in
                        XCTAssertNil(error)
                        if error != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        XCTAssertEqual(card?.state, .DECLINED_TERMS_AND_CONDITIONS)
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCreditCardSelectVerificationMethod()
    {
        let expectation = super.expectation(description: "'selectVerificationType' selects verification method")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard)
                    {
                        (card) in
                        self.testHelper.selectVerificationType(expectation, card: card)
                        {
                            (verificationMethod) in
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 10, handler: nil)
    }

    func testCreditCardVerify()
    {
        let expectation = super.expectation(description: "'creditCard' verify card with id")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    self.testHelper.acceptTermsForCreditCard(expectation, card: creditCard)
                    {
                        (card) in
                        self.testHelper.selectVerificationType(expectation, card: card)
                        {
                            (verificationMethod) in
                            
                            self.testHelper.verifyCreditCard(expectation, verificationMethod: verificationMethod)
                            {
                                (verificationMethod) in
                                self.testHelper.deleteUser(user, expectation: expectation)
                            }
                        }
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testUserListDevisesListsDevices()
    {
        let expectation = super.expectation(description: "test 'device' retrieves devices by user id")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                user?.listDevices(limit: 10, offset: 0)
                {
                    (result, error) in
                    XCTAssertNil(error)
                    
                    if error != nil
                    {
                        expectation.fulfill()
                        return
                    }
                    
                    XCTAssertNotNil(result)
                    XCTAssertEqual(result?.results?.count, 1)
                    
                    for deviceInfo in result!.results!
                    {
                        XCTAssertNotNil(deviceInfo.deviceIdentifier)
                        XCTAssertNotNil(deviceInfo.metadata)
                    }
                    
                    self.testHelper.deleteUser(user, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testUserCreateNewDeviceCreatesDevice()
    {
        let expectation = super.expectation(description: "test 'user.createDevice' creates device")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.deleteUser(user, expectation: expectation)
            }
        }

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceDelete()
    {
        let expectation = super.expectation(description: "test 'device.deleteDevice' deletes device")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                user?.listDevices(limit: 10, offset: 0)
                {
                    (result, error) in
                    XCTAssertNil(error)
                    
                    if error != nil
                    {
                        expectation.fulfill()
                        return
                    }
                    
                    XCTAssertNotNil(result)
                    XCTAssertEqual(result?.results?.count, 1)
                    
                    let deviceInfo = result!.results!.first!
                    
                    XCTAssertNotNil(deviceInfo.deviceIdentifier)
                    XCTAssertNotNil(deviceInfo.metadata)
                    
                    deviceInfo.deleteDeviceInfo
                    {
                        (error) in
                        XCTAssertNil(error)
                        
                        if error != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        user?.listDevices(limit: 10, offset: 0)
                        {
                            (result, error) in
                            XCTAssertNil(error)
                            
                            if error != nil
                            {
                                expectation.fulfill()
                                return
                            }
                            
                            XCTAssertEqual(result?.totalResults, 0)
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                    }
                }
            }
        }

        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceUserRetrievesUser()
    {
        let expectation = super.expectation(description: "test 'device.user' retrieves user ")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                
                device?.user
                {
                    (retrievedUser, error) in
                    
                    XCTAssertNotNil(user)
                    XCTAssertNil(error)
                    
                    if error != nil
                    {
                        expectation.fulfill()
                        return
                    }
                    
                    self.testHelper.deleteUser(retrievedUser, expectation: expectation)
                }
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testDeviceUpdate()
    {
        let expectation = super.expectation(description: "test 'device' update device")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                
                let firmwareRev = "2.7.7.7"
                let softwareRev = "6.8.1"
                device?.update(firmwareRev, softwareRevision: softwareRev, notifcationToken: nil, completion:
                {
                    (updatedDevice, error) -> Void in
                    XCTAssertNil(error)
                    
                    if error != nil
                    {
                        expectation.fulfill()
                        return
                    }
                    
                    XCTAssertNotNil(updatedDevice)
                    XCTAssertEqual(updatedDevice!.softwareRevision!, softwareRev)
                    XCTAssertEqual(updatedDevice!.firmwareRevision!, firmwareRev)
                        
                    self.testHelper.deleteUser(user, expectation: expectation)
                })
            }
        }
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    //ejp - need to populate a few cards with lots of commits, and then fetch the commits.
    // Test should be reactivated as part of PLAT-1648
    func skipped_testCheckCommits() {
        let expectation = super.expectation(description: "fetch commits (multiples) for a device")
        var masterCard : CreditCard?
        var masterUser : User?
        var masterDevice : DeviceInfo?
        var masterCommitList : [Commit]?
            
        self.testHelper.createAndLoginUser(expectation) {
            user in
            masterUser = user!
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                masterDevice = device!
                self.testHelper.createEricCard(expectation, pan:"9999411122220033", expMonth:12, expYear:2019, user: user) {
                    (user, card) in
                    self.testHelper.acceptTermsForCreditCard(expectation, card:card) {
                        card in
                        masterCard = card!
                        expectation.fulfill()
                    }
                }
            }
        }
        super.waitForExpectations(timeout: 20, handler:nil)

        var accepted = 0
        let cardExpectation = super.expectation(description: "creating cards 1-9")
        for i in 1...9 {
            self.testHelper.createEricCard(expectation, pan:"9999411122220\(i)33", expMonth:i, expYear:2019, user: masterUser!) {
                (user, card) in

                debugPrint("card creation done \(card)")

                self.testHelper.acceptTermsForCreditCard(expectation, card:card) {
                    card in
                    accepted+=1 //can't use i because closure has it at 10 when I hit this callback
                    if (accepted==9) {
                        cardExpectation.fulfill()
                    }
                }
            }
        }
        super.waitForExpectations(timeout: 40, handler:nil)

        var now = Date()
        debugPrint("All card creation/acceptance done \(now)")
        
        for i in 0...4 {
            let synchronizer = super.expectation(description: "deactivate reactivate")
            self.testHelper.deactivateCreditCard(synchronizer, creditCard:masterCard) {
                card in
                now = NSDate() as Date
                debugPrint("deactivate card done: \(i) \(now)")
                
                card?.reactivate(causedBy: .CARDHOLDER, reason: "I like pizza", completion: {
                    (pending, card, error) in
                    now = NSDate() as Date
                    debugPrint("Reactivate done: \(i) \(now)")
                    masterCard = card!
                    XCTAssertNil(error)
                    synchronizer.fulfill()
                })
            }
            super.waitForExpectations(timeout: 10, handler:nil)
        }

        let commit_checker = super.expectation(description: "check the commits")

        masterDevice!.listCommits(commitsAfter: nil, limit: 100, offset: 0) {
            (commits, error) in
            XCTAssertNil(error)
            if error != nil { commit_checker.fulfill(); return }
            XCTAssertEqual(commits?.totalResults, 32/*1+1+9+10+1+5+5*/, "Should have 10 create (1+1 set default + 9 activates), '10' activates, 1 more reset default for the deactivate, 10 activate-deactivate")
            XCTAssertEqual(commits?.results?.count, 32, "32 results just like total results")
            for result in (commits?.results!)! {
                debugPrint("Result: \(result.commitType!)")
                if (masterCommitList == nil) {
                    masterCommitList = [result]
                } else {
                    masterCommitList!.append(result)
                }
            }
            commit_checker.fulfill()
        }
        super.waitForExpectations(timeout: 10, handler:nil)

        let commit_checker2 = super.expectation(description: "check the commits")
        let commit_checker3 = super.expectation(description: "check the commits")
        let commit_checker4 = super.expectation(description: "check the commits")
        let commit_checker5 = super.expectation(description: "check the commits")

        //page 0, limited to 10.
        masterDevice!.listCommits(commitsAfter: nil, limit: 10, offset: 0) {
            (commits, error) in
            XCTAssertNil(error)
            if error != nil { commit_checker.fulfill(); return }
            for idx in 0...9 {
                XCTAssertEqual(masterCommitList![idx].commit, commits?.results?[idx].commit, "Compare commit idx \(idx)")
            }
            XCTAssertEqual(commits?.results?.count, 10, "Should have 10 when I limit results")
            XCTAssertEqual(commits?.totalResults, 32, "Should have 32 total though")
            commit_checker2.fulfill()
        }
        
        //page 2, limited to 8
        masterDevice!.listCommits(commitsAfter: nil, limit: 8, offset: 10) {
            (commits, error) in
            XCTAssertNil(error)
            if error != nil { commit_checker.fulfill(); return }
            XCTAssertEqual(commits?.results?.count, 8, "Should have 8 when I limit results")
            XCTAssertEqual(commits?.totalResults, 32, "Should have 32 total though")
            for idx in 10...17 {
                XCTAssertEqual(masterCommitList![idx].commit, commits?.results?[idx-10].commit, "Compare commit idx \(idx)")
            }
            commit_checker3.fulfill()
        }
        
        //page "3", limited to 20. Gets 1 item.
        masterDevice!.listCommits(commitsAfter: nil, limit: 20, offset: 31) {
            (commits, error) in
            XCTAssertNil(error)
            if error != nil { commit_checker.fulfill(); return }
            XCTAssertEqual(commits?.results?.count, 1, "Should have 1 when I limit results")
            XCTAssertEqual(commits?.totalResults, 32, "Should have 32 total though")

            for idx in 31...31 {
                XCTAssertEqual(masterCommitList![idx].commit, commits?.results?[idx-31].commit, "Compare commit idx \(idx)")
            }

            commit_checker4.fulfill()
        }
        masterDevice!.listCommits(commitsAfter: nil, limit: 200, offset: 200) {
            (commits, error) in
            XCTAssertNil(error)
            if error != nil { commit_checker.fulfill(); return }
            XCTAssertEqual(commits?.totalResults, 32, "Should have 0 when I hit terminal page")
            XCTAssertEqual(commits?.results?.count, 0, "Should have 0 results when I go off the edge of the earth")
            commit_checker5.fulfill()
        }

        super.waitForExpectations(timeout: 20, handler:nil)
    }

    func testDeviceRetrievesCommitsFromDevice()
    {
        let expectation = super.expectation(description: "test 'device' retrieving commits from device")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                
                user?.listDevices(limit: 10, offset: 0)
                {
                    (result, error) in
                    
                    XCTAssertNil(error)
                    
                    if error != nil
                    {
                        expectation.fulfill()
                        return
                    }
                    
                    result?.results?.first?.listCommits(commitsAfter: nil, limit: 10, offset: 0)
                    {
                        (commits, error) in
                        
                        XCTAssertNil(error)
                        
                        if error != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        XCTAssertNotNil(commits)
                        XCTAssertNotNil(commits?.limit)
                        XCTAssertNotNil(commits?.totalResults)
                        XCTAssertNotNil(commits?.links)
                        XCTAssertNotNil(commits?.results)
                        
                        for commit in commits!.results!
                        {
                            XCTAssertNotNil(commit.commitType)
                            XCTAssertNotNil(commit.payload)
                            XCTAssertNotNil(commit.commit)
                        }
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRelationshipsCreatesAndDeletesRelationship()
    {
        let expectation = super.expectation(description: "test 'relationships' creates and deletes relationship")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    user?.createRelationship(creditCardId: creditCard!.creditCardId!, deviceId: device!.deviceIdentifier!)
                    {
                        (relationship, error) -> Void in
                        XCTAssertNil(error)
                        
                        if error != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        XCTAssertNotNil(device)
                        XCTAssertNotNil(relationship?.device)
                        XCTAssertNotNil(relationship?.card)
                        
                        relationship?.deleteRelationship
                        {
                            (error) in
                            
                            XCTAssertNil(error)
                            
                            if error != nil
                            {
                                expectation.fulfill()
                                return
                            }
                            
                            device?.deleteDeviceInfo
                            {
                                (error) -> Void in
                                
                                XCTAssertNil(error)
                                
                                if error != nil
                                {
                                    expectation.fulfill()
                                    return
                                }
                                
                                self.testHelper.deleteUser(user, expectation: expectation)
                            }
                        }
                    }
                }
            }
        }
        
        super.waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testAssetsRetrievesAsset()
    {
        let expectation = super.expectation(description: "'assets' retrievs asset")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    creditCard?.cardMetaData?.brandLogo?.first?.retrieveAsset
                    {
                        (asset, error) in
                        
                        XCTAssertNil(error)
                        
                        if error != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        self.testHelper.deleteUser(user, expectation: expectation)
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testTransactionRetrievesTransactionsByUserId()
    {
        let expectation = super.expectation(description: "'transaction' retrieves transactions by user id")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            self.testHelper.createDevice(expectation, user: user)
            {
                (user, device) in
                self.testHelper.createCreditCard(expectation, user: user)
                {
                    (user, creditCard) in
                    
                    creditCard?.listTransactions(limit: 1, offset:0)
                    {
                        
                        (transactions, error) -> Void in
                        
                        XCTAssertNil(error)
                        
                        if error != nil
                        {
                            expectation.fulfill()
                            return
                        }
                        
                        XCTAssertNotNil(transactions)
                        XCTAssertNotNil(transactions?.limit)
                        XCTAssertNotNil(transactions?.totalResults)
                        XCTAssertNotNil(transactions?.links)
                        XCTAssertNotNil(transactions?.results)
                        
                        if let transactionsResults = transactions!.results
                        {
                            if transactionsResults.count > 0
                            {
                                for transactionInfo in transactionsResults
                                {
                                    XCTAssertNotNil(transactionInfo.transactionId)
                                    XCTAssertNotNil(transactionInfo.transactionType)
                                }
                            }
                            
                            self.testHelper.deleteUser(user, expectation: expectation)
                        }
                    }
                }
            }
        }

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    /**
     tests all cases for NSTimeIntervalTransform
    */
    func testCompareCreatedEpochToCreatedTS()
    {
        let expectation = super.expectation(description: "'createdEpoch' converted correctly to seconds from ms")
        
        self.testHelper.createAndLoginUser(expectation)
        {
            [unowned self](user) in
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let nsdate = dateFormatter.date(from: (user?.created)!)
            
            let epochDiff = abs((nsdate?.timeIntervalSince1970)! - (user?.createdEpoch)!)
            
            XCTAssertLessThan(epochDiff, 1, "validate epoch converted correctly")
            
            self.testHelper.deleteUser(user, expectation: expectation)
        }

        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testNSTimeIntervalToInt()
    {
        let expectation = super.expectation(description: "NSTimeInterval converted to int correctly")
        
        let currentTime = Date().timeIntervalSince1970
        let timeTransform = NSTimeIntervalTransform()
        let timeAsInt = timeTransform.transformToJSON(currentTime)
        
        let intMirror = Mirror(reflecting: timeAsInt)
        debugPrint(String(describing: intMirror.subjectType))
        XCTAssertTrue(String(describing: intMirror.subjectType) == "Optional<Int64>")
        
        expectation.fulfill()
        
        super.waitForExpectations(timeout: 10, handler: nil)
    }
    
//    func testAPDUPackageConfirm()
//    {
//        let expectation = super.expectationWithDescription("'APDUPackage' confirms package")
//        
//        self.session.login(username: self.username, password: self.password)
//        {
//            [unowned self](error) -> Void in
//            XCTAssertNil(error)
//            XCTAssertTrue(self.session.isAuthorized)
//            
//            if !self.session.isAuthorized
//            {
//                expectation.fulfill()
//                return
//            }
//        
//            let package = ApduPackage()
//            package.packageId = "0828a2a8-2ad6-4ea5-9f3c-188983986f25"
//            package.state = "SUCCESSFUL"
//            package.executed = "2015-12-15T23:54:20.510Z"
//            package.executedDuration = 999
//
//            let resp = APDUCommand()
//            resp.commandId = "c3930e8d-0c87-454c-9d5c-bfda6e6e1eb1"
//            resp.responseCode = "9000"
//            resp.responseData = "011234567899000"
//            
//            package.apduCommands = [ resp ]
//            
//            self.client.confirmAPDUPackage(package, completion:
//            {
//                (error) -> Void in
//                
//                XCTAssertNil(error)
//                
//                expectation.fulfill()
//            })
//        }
//        
//        super.waitForExpectationsWithTimeout(10, handler: nil)
//    }
    
    // Helpers
    

}
