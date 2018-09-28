import XCTest
import Nimble

@testable import FitpaySDK

class CreditCardTests: XCTestCase {
    
    private let mockModels = MockModels()
    private let mockRestRequest = MockRestRequest()
    private var session: RestSession?
    private var client: RestClient?
    
    override func setUp() {
        session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session!.accessToken = "authorized"
        
        client = RestClient(session: session!, restRequest: mockRestRequest)
    }
        
    func testCreditCardParsing() {
        let creditCard = mockModels.getCreditCard()

        expect(creditCard?.creditCardId).to(equal(mockModels.someId))
        expect(creditCard?.userId).to(equal(mockModels.someId))
        expect(creditCard?.created).to(equal(mockModels.someDate))
        expect(creditCard?.createdEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(creditCard?.state).to(equal(TokenizationState.notEligible))
        expect(creditCard?.cardType).to(equal(mockModels.someType))
        expect(creditCard?.termsAssetId).to(equal(mockModels.someId))
        expect(creditCard?.eligibilityExpiration).to(equal(mockModels.someDate))
        expect(creditCard?.encryptedData).to(equal(mockModels.someEncryptionData))
        expect(creditCard?.targetDeviceId).to(equal(mockModels.someId))
        expect(creditCard?.targetDeviceType).to(equal(mockModels.someType))
        expect(creditCard?.externalTokenReference).to(equal("someToken"))
                
        expect(creditCard?.links).toNot(beNil())
        expect(creditCard?.cardMetaData).toNot(beNil())
        expect(creditCard?.termsAssetReferences).toNot(beNil())
        expect(creditCard?.verificationMethods).toNot(beNil())
        
        expect(creditCard?.topOfWalletAPDUCommands).toNot(beNil())
        expect(creditCard?.topOfWalletAPDUCommands?.count).to(equal(1))

        let json = creditCard?.toJSON()
        expect(json?["creditCardId"] as? String).to(equal(mockModels.someId))
        expect(json?["createdTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["createdTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["state"] as? String).to(equal("NOT_ELIGIBLE"))
        expect(json?["cardType"] as? String).to(equal(mockModels.someType))
        expect(json?["termsAssetId"] as? String).to(equal(mockModels.someId))
        expect(json?["eligibilityExpiration"] as? String).to(equal(mockModels.someDate))
        expect(json?["eligibilityExpirationEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["encryptedData"] as? String).to(equal(mockModels.someEncryptionData))
        expect(json?["targetDeviceId"] as? String).to(equal(mockModels.someId))
        expect(json?["targetDeviceType"] as? String).to(equal(mockModels.someType))
        expect(json?["externalTokenReference"] as? String).to(equal("someToken"))
        
        expect(json?["_links"]).toNot(beNil())
        expect(json?["cardMetaData"]).toNot(beNil())
        expect(json?["termsAssetReferences"]).toNot(beNil())
        expect(json?["verificationMethods"]).toNot(beNil())
    }
    
    func testAvailable() {
        let creditCard = mockModels.getCreditCard()
        
        expect(creditCard?.acceptTermsAvailable).to(beTrue())
        expect(creditCard?.declineTermsAvailable).to(beTrue())
        expect(creditCard?.deactivateAvailable).to(beTrue())
        expect(creditCard?.reactivateAvailable).to(beTrue())
        expect(creditCard?.makeDefaultAvailable).to(beTrue())
        expect(creditCard?.listTransactionsAvailable).to(beTrue())
        expect(creditCard?.verificationMethodsAvailable).to(beTrue())
        expect(creditCard?.selectedVerificationMethodAvailable).to(beTrue())
    }
    
    func testNotAvailable() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.links = []
        
        expect(creditCard?.acceptTermsAvailable).to(beFalse())
        expect(creditCard?.declineTermsAvailable).to(beFalse())
        expect(creditCard?.deactivateAvailable).to(beFalse())
        expect(creditCard?.reactivateAvailable).to(beFalse())
        expect(creditCard?.makeDefaultAvailable).to(beFalse())
        expect(creditCard?.listTransactionsAvailable).to(beFalse())
        expect(creditCard?.verificationMethodsAvailable).to(beFalse())
        expect(creditCard?.selectedVerificationMethodAvailable).to(beFalse())
    }
    
    func testGetAcceptTermsURL() {
        let creditCard = mockModels.getCreditCard()
        expect(creditCard?.getAcceptTermsUrl()).to(contain("acceptTerms"))
    }
    
    func testSetAcceptTermsUrl() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.setAcceptTermsUrl(acceptTermsUrl: "newUrl")
        
        expect(creditCard?.getAcceptTermsUrl()).to(equal("newUrl"))
        
        creditCard?.links = []
        creditCard?.setAcceptTermsUrl(acceptTermsUrl: "newNewUrl")
        expect(creditCard?.getAcceptTermsUrl()).to(beNil())
    }
    
    func testGetCardNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.getCard { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testGetCard() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.getCard { (card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                done()
            }
        }
    }
    
    func testDeleteCardNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.deleteCard { error in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testDeleteCard() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.deleteCard { error in
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testUpdateCardNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            let address = Address(street1: "123 Lane", street2: "2", street3: "3", city: "Boulder", state: "Colorado", postalCode: "80401", countryCode: "US")
            creditCard?.updateCard(name: "John Wick", address: address) { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testUpdateCard() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            let address = Address(street1: "123 Lane", street2: "2", street3: "3", city: "Boulder", state: "Colorado", postalCode: "80401", countryCode: "US")
            creditCard?.updateCard(name: "John Wick", address: address) { (card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                done()
            }
        }
    }
    
    func testAcceptTermsNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.acceptTerms { (_, _, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testAcceptTerms() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.acceptTerms { (pending, card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                expect(pending).to(beFalse())
                done()
            }
        }
    }
    
    func testDeclineTermsNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.declineTerms { (_, _, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testDeclineTerms() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.declineTerms { (pending, card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                expect(pending).to(beFalse())
                done()
            }
        }
    }
    
    func testDeactivateNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.deactivate(causedBy: .cardholder, reason: "none") { (_, _, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testDeactivate() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.deactivate(causedBy: .cardholder, reason: "none") { (pending, card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                expect(pending).to(beFalse())
                done()
            }
        }
    }
    
    func testReactivateNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.reactivate(causedBy: .cardholder, reason: "none") { (_, _, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testReactivate() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.reactivate(causedBy: .cardholder, reason: "none") { (pending, card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                expect(pending).to(beFalse())
                done()
            }
        }
    }
    
    func testMakeDefaultNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.makeDefault { (_, _, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testMakeDefault() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.makeDefault { (pending, card, error) in
                expect(error).to(beNil())
                expect(card).toNot(beNil())
                expect(pending).to(beFalse())
                done()
            }
        }
    }
    
    func testMakeDefaultWithDeviceId() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.makeDefault(deviceId: "123") { (pending, card, error) in
                let urlString = try! self.mockRestRequest.lastUrl?.asURL().absoluteString

                expect(error).to(beNil())
                expect(card).toNot(beNil())
                expect(pending).to(beFalse())
                expect(urlString).to(contain("deviceId=123"))
                done()
            }
        }
    }
    
    func testListTransactionsNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.listTransactions(limit: 10, offset: 0) { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testListTransactions() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.listTransactions(limit: 10, offset: 0) { (transactionResults, error) in
                expect(error).to(beNil())
                expect(transactionResults).toNot(beNil())
                expect(transactionResults?.results?.count).to(equal(10))
                done()
            }
        }
    }
    
    func testGetVerificationMethodsNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.getVerificationMethods { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testGetVerificationMethods() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.getVerificationMethods { (verificationResults, error) in
                expect(error).to(beNil())
                expect(verificationResults).toNot(beNil())
                expect(verificationResults?.results?.count).to(equal(1))
                done()
            }
        }
    }
    
    func testGetSelectedVerificationMethodNoClient() {
        let creditCard = mockModels.getCreditCard()
        waitUntil { done in
            creditCard?.getSelectedVerification { (_, error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                done()
            }
        }
    }
    
    func testGetSelectedVerificationMethod() {
        let creditCard = mockModels.getCreditCard()
        creditCard?.client = client
        waitUntil { done in
            creditCard?.getSelectedVerification { (verification, error) in
                expect(error).to(beNil())
                expect(verification).toNot(beNil())
                done()
            }
        }
    }
    
}
