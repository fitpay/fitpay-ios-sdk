import XCTest
import Alamofire
import Nimble

@testable import FitpaySDK

class UsersTests: XCTestCase {
    let mockModels = MockModels()
    
    var user: User!
    var restClient: RestClient!
    var testHelper: TestHelper!
    
    let restRequest = MockRestRequest()
    
    override func setUp() {
        let session = RestSession(restRequest: restRequest)
        session.accessToken = "authorized"

        restClient = RestClient(session: session, restRequest: restRequest)
        testHelper = TestHelper(session: session, client: restClient)
        restClient.keyPair = MockSECP256R1KeyPair()
        
        user = mockModels.getUser()
    }
    
    func testUserParsing() {
        let user = mockModels.getUser()

        XCTAssertNotNil(user?.links)
        XCTAssertEqual(user?.id, mockModels.someId)
        XCTAssertEqual(user?.created, mockModels.someDate)
        XCTAssertEqual(user?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.lastModified, mockModels.someDate)
        XCTAssertEqual(user?.lastModifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.encryptedData, "some data")

        let json = user?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["id"] as? String, mockModels.someId)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["lastModifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["lastModifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["encryptedData"] as? String, "some data")
    }

    func testListCreditCardsAvailable() {
        let listCreditCardsAvailable = user?.listCreditCardsAvailable
        expect(listCreditCardsAvailable).to(beTrue())
        
        user.links = nil
        
        let listCreditCardsNotAvailable = user?.listCreditCardsAvailable
        expect(listCreditCardsNotAvailable).toNot(beTrue())
    }
    
    func testListDevicesAvailable() {
        let listDevicesAvailable = user?.listDevicesAvailable
        expect(listDevicesAvailable).to(beTrue())
        
        user.links = nil
        
        let listDevicesNotAvailable = user?.listDevicesAvailable
        expect(listDevicesNotAvailable).toNot(beTrue())
    }
    
    func testCreateCreditCardNoClient() {
        let address = Address(street1: "123 Lane", street2: nil, street3: nil, city: "Boulder", state: "Colorado", postalCode: "80401", countryCode: nil)
        let creditCardInfo = CardInfo(pan: "123456", expMonth: 12, expYear: 2020, cvv: "123", name: "John Wick", address: address, riskData: nil)
        
        waitUntil { done in
            self.user.createCreditCard(cardInfo: creditCardInfo) { (card, error) in
                expect(card).to(beNil())
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))

                done()
            }
        }
    }
    
    func testCreateCreditCard() {
        let address = Address(street1: "123 Lane", street2: nil, street3: nil, city: "Boulder", state: "Colorado", postalCode: "80401", countryCode: nil)
        let creditCardInfo = CardInfo(pan: "123456", expMonth: 12, expYear: 2020, cvv: "123", name: "John Wick", address: address, riskData: nil)
        user.client = restClient
        
        waitUntil { done in
            self.user.createCreditCard(cardInfo: creditCardInfo) { (card, error) in
                expect(self.restRequest.lastParams?.keys).toNot(contain("deviceId"))
                let lastEncodingAsJson = self.restRequest.lastEncoding as? JSONEncoding
                expect(lastEncodingAsJson).toNot(beNil())
                expect(card).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testCreateCreditCardWithDeviceId() {
        let address = Address(street1: "123 Lane", street2: nil, street3: nil, city: "Boulder", state: "Colorado", postalCode: "80401", countryCode: nil)
        let creditCardInfo = CardInfo(pan: "123456", expMonth: 12, expYear: 2020, cvv: "123", name: "John Wick", address: address, riskData: nil)
        user.client = restClient

        waitUntil { done in
            self.user.createCreditCard(cardInfo: creditCardInfo, deviceId: "1234") { (card, error) in
                expect(self.restRequest.lastParams?["deviceId"] as? String).to(equal("1234"))
                let lastEncodingAsJson = self.restRequest.lastEncoding as? JSONEncoding
                expect(lastEncodingAsJson).toNot(beNil())
                expect(card).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testGetCreditCardsNoClient() {
        waitUntil { done in
            self.user.getCreditCards(excludeState: [], limit: 10, offset: 0) { (cardResults, error) in
                expect(cardResults).to(beNil())
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                
                done()
            }
        }
    }
    
    func testGetCreditCards() {
        user.client = restClient
        
        waitUntil { done in
            self.user.getCreditCards(excludeState: [], limit: 10, offset: 0) { (cardResults, error) in
                expect(cardResults).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testGetCreditCardsWithDeviceId() {
        user.client = restClient

        waitUntil { done in
            self.user?.getCreditCards(excludeState: [], limit: 10, offset: 0, deviceId: "1234") { (card, error) in
                expect(self.restRequest.lastParams?["deviceId"] as? String).to(equal("1234"))
                let lastEncodingAsURL = self.restRequest.lastEncoding as? URLEncoding
                expect(lastEncodingAsURL).toNot(beNil())
                expect(card).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testGetDevicesNoClient() {
        waitUntil { done in
            self.user.getDevices(limit: 10, offset: 0) { (cardResults, error) in
                expect(cardResults).to(beNil())
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                
                done()
            }
        }
    }
    
    func testGetDevices() {
        user.client = restClient
        
        waitUntil { done in
            self.user.getDevices(limit: 10, offset: 0) { (cardResults, error) in
                expect(cardResults).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testCreateDeviceNoClient() {
        waitUntil { done in
            let device = Device()
            self.user.createDevice(device) { (device, error) in
                expect(device).to(beNil())
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                
                done()
            }
        }
    }
    
    func testCreateDevice() {
        user.client = restClient
        
        waitUntil { done in
            let device = Device()
            self.user.createDevice(device) { (device, error) in
                expect(device).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testDeleteUserNoClient() {
        waitUntil { done in
            self.user.deleteUser { (error) in
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                
                done()
            }
        }
    }
    
    func testDeleteNoUser() {
        user.client = restClient
        
        waitUntil { done in
            self.user.deleteUser { (error) in
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testUpdateUserNoClient() {
        waitUntil { done in
            self.user.updateUser(firstName: "John", lastName: "Wick", birthDate: nil, originAccountCreated: nil, termsAccepted: nil, termsVersion: nil) { (user, error) in
                expect(user).to(beNil())
                expect(error).toNot(beNil())
                expect(error?.localizedDescription).to(equal("RestClient is not set."))
                
                done()
            }
        }
    }
    
    func testUpdateUser() {
        user.client = restClient
        
        waitUntil { done in
            self.user.updateUser(firstName: "John", lastName: "Wick", birthDate: nil, originAccountCreated: nil, termsAccepted: nil, termsVersion: nil) { (user, error) in
                expect(user).toNot(beNil())
                expect(error).to(beNil())
                
                done()
            }
        }
    }

}
