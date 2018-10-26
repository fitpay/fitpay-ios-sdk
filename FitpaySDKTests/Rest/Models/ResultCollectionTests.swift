import XCTest
import Nimble

@testable import FitpaySDK

class ResultCollectionTests: XCTestCase {
    
    private let mockModels = MockModels()
    
    private var restClient: RestClient!
    private let restRequest = MockRestRequest()
    
    override func setUp() {
        let session = RestSession(restRequest: restRequest)
        session.accessToken = "authorized"
        
        restClient = RestClient(session: session, restRequest: restRequest)
    }
        
    func testResultCollectionParsing() {
        let resultCollection = mockModels.getResultCollection()

        expect(resultCollection?.links).toNot(beNil())
        expect(resultCollection?.limit).to(equal(1))
        expect(resultCollection?.offset).to(equal(1))
        expect(resultCollection?.totalResults).to(equal(1))
        expect(resultCollection?.results).toNot(beNil())
        expect(resultCollection?.client).to(beNil())

        let json = resultCollection?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["limit"] as? Int).to(equal(1))
        expect(json?["offset"] as? Int).to(equal(1))
        expect(json?["totalResults"] as? Int).to(equal(1))
    }
    
    func testResultCollectionVerificationMethodParsing() {
        let resultCollection = mockModels.getResultVerificationMethodCollection()
        
        expect(resultCollection?.totalResults).to(equal(1))
        expect(resultCollection?.results).toNot(beNil())
        expect(resultCollection?.results?.count).to(equal(1))
    }
    
    func testNextAvailable() {
        let resultCollection = mockModels.getResultCollection()

        let nextAvailable = resultCollection?.nextAvailable
        expect(nextAvailable).to(beTrue())

        resultCollection?.links = nil

        let nextNotAvailable = resultCollection?.nextAvailable
        expect(nextNotAvailable).toNot(beTrue())
    }
    
    func testLastAvailable() {
        let resultCollection = mockModels.getResultCollection()
        
        let lastAvailable = resultCollection?.lastAvailable
        expect(lastAvailable).to(beTrue())
        
        resultCollection?.links = nil
        
        let lastNotAvailable = resultCollection?.lastAvailable
        expect(lastNotAvailable).toNot(beTrue())
    }
    
    func testPreviousAvailable() {
        let resultCollection = mockModels.getResultCollection()
        
        let previousAvailable = resultCollection?.previousAvailable
        expect(previousAvailable).to(beTrue())
        
        resultCollection?.links = nil
        
        let previousNotAvailable = resultCollection?.previousAvailable
        expect(previousNotAvailable).toNot(beTrue())
    }
    
    func testClientGetReturnsClientIfClientPresent() {
        let resultCollection = mockModels.getResultCollection()
        let client = RestClient(session: RestSession())
        
        resultCollection?.client = client
        expect(resultCollection?.client).to(equal(client))
    }
    
    func testClientGetReturnsClientIfResultsHaveClient() {
        let resultCollection = mockModels.getResultCollection()
        let client = RestClient(session: RestSession())

        expect(resultCollection?.client).to(beNil())
        resultCollection?.results?.first?.client = client
        
        expect(resultCollection?.client).to(equal(client))
    }
    
    func testClientSetSetsRestClient() {
        let resultCollection = mockModels.getResultCollection()
        let client = RestClient(session: RestSession())
        
        expect(resultCollection?.results?.first?.client).to(beNil())
        resultCollection?.client = client
        
        expect(resultCollection?.results?.first?.client).to(equal(client))
    }
    
    func testCollectAllAvailableNoClient() {
        let resultCollection = mockModels.getResultCollection()

        waitUntil { done in
            resultCollection?.collectAllAvailable { (devices, error) in
                expect(devices).to(beNil())
                expect(error).toNot(beNil())
                
                done()
            }
        }
    }
    
    func testCollectAllAvailableNoNext() {
        let resultCollection = mockModels.getResultCollection()
        resultCollection?.links?["next"] = nil
        
        waitUntil { done in
            resultCollection?.collectAllAvailable { (devices, error) in
                expect(devices).toNot(beNil())
                expect(devices?.count).to(equal(1))
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testCollectAllAvailable() {
        let resultCollection = mockModels.getResultCollection()
        resultCollection?.client = restClient
        
        waitUntil { done in
            resultCollection?.collectAllAvailable { (devices, error) in
                expect(devices).toNot(beNil())
                expect(devices?.count).to(equal(2))
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testNextNoClient() {
        let resultCollection = mockModels.getResultCollection()
        
        waitUntil { done in
            resultCollection?.next { (collection: ResultCollection<Device>?, error: ErrorResponse?) in
                expect(collection).to(beNil())
                expect(error).toNot(beNil())

                done()
            }
        }
    }
    
    func testNext() {
        let resultCollection = mockModels.getResultCollection()
        resultCollection?.client = restClient
        
        waitUntil { done in
            resultCollection?.next { (collection: ResultCollection<Device>?, error: ErrorResponse?) in
                expect(collection).toNot(beNil())
                expect(collection?.results?.count).to(equal(1))
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testLastNoClient() {
        let resultCollection = mockModels.getResultCollection()
        
        waitUntil { done in
            resultCollection?.last { (collection: ResultCollection<Device>?, error: ErrorResponse?) in
                expect(collection).to(beNil())
                expect(error).toNot(beNil())
                
                done()
            }
        }
    }
    
    func testLast() {
        let resultCollection = mockModels.getResultCollection()
        resultCollection?.client = restClient

        waitUntil { done in
            resultCollection?.last { (collection: ResultCollection<Device>?, error: ErrorResponse?) in
                expect(collection).toNot(beNil())
                expect(collection?.results?.count).to(equal(1))
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
    func testPreviousNoClient() {
        let resultCollection = mockModels.getResultCollection()
        
        waitUntil { done in
            resultCollection?.previous { (collection: ResultCollection<Device>?, error: ErrorResponse?) in
                expect(collection).to(beNil())
                expect(error).toNot(beNil())
                
                done()
            }
        }
    }
    
    func testPrevious() {
        let resultCollection = mockModels.getResultCollection()
        resultCollection?.client = restClient

        waitUntil { done in
            resultCollection?.previous { (collection: ResultCollection<Device>?, error: ErrorResponse?) in
                expect(collection).toNot(beNil())
                expect(collection?.results?.count).to(equal(1))
                expect(error).to(beNil())
                
                done()
            }
        }
    }
    
}
