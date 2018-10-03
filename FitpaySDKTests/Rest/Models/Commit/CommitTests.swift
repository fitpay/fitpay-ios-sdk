import XCTest
import Nimble

@testable import FitpaySDK

class CommitTests: XCTestCase {
    
    private let mockModels = MockModels()
    private let mockRestRequest = MockRestRequest()
    private var session: RestSession?
    private var client: RestClient?
    
    override func setUp() {
        session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session!.accessToken = "authorized"
        
        client = RestClient(session: session!, restRequest: mockRestRequest)
    }
    
    func testCommitParsing() {
        let commit = mockModels.getCommit()
        
        expect(commit?.links).toNot(beNil())
        expect(commit?.commitTypeString).to(equal("UNKNOWN"))
        expect(commit?.created).to(equal(CLong(mockModels.timeEpoch)))
        expect(commit?.previousCommit).to(equal("2"))
        expect(commit?.commitId).to(equal(mockModels.someId))
        expect(commit?.encryptedData).to(equal(mockModels.someEncryptionData))
        
        let json = commit?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["commitType"] as? String).to(equal("UNKNOWN"))
        expect(json?["createdTs"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["previousCommit"] as? String).to(equal("2"))
        expect(json?["commitId"] as? String).to(equal(mockModels.someId))
        expect(json?["encryptedData"] as? String).to(equal(mockModels.someEncryptionData))
    }
    
    func testClientDidSet() {
        let commit = mockModels.getAPDUCommit()
        commit?.payload = mockModels.getPayload()
        commit?.payload?.creditCard = mockModels.getCreditCard()
        
        expect(commit?.payload?.creditCard?.client).to(beNil())
        commit?.client = client
        expect(commit?.payload?.creditCard?.client).to(equal(client))

    }
    
    func testConfirmNonAPDUCommitAPDU() {
        let commit = mockModels.getAPDUCommit()
        
        commit?.confirmNonAPDUCommitWith(result: .success) { (error) in
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("Unhandled error"))
        }
    }
    
    func testConfirmNonAPDUCommitNoClient() {
        let commit = mockModels.getCommit()
        
        commit?.confirmNonAPDUCommitWith(result: .success) { (error) in
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testConfirmNonAPDUCommitNoLink() {
        let commit = mockModels.getCommit()
        commit?.links = nil
        
        commit?.confirmNonAPDUCommitWith(result: .success) { (error) in
            expect(error).to(beNil())
        }
    }
    
    func testConfirmNonAPDUCommit() {
        let commit = mockModels.getCommit()
        commit?.client = client
        
        commit?.confirmNonAPDUCommitWith(result: .success) { (error) in
            expect(error).to(beNil())
        }
    }
        
    func testConfimAPDUNonAPDU() {
        let commit = mockModels.getCommit()
        
        commit?.confirmAPDU { (error) in
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("Unhandled error"))
        }
    }
    
    func testConfimAPDUNoPackage() {
        let commit = mockModels.getAPDUCommit()
        
        commit?.confirmAPDU { (error) in
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("Unhandled error"))
        }
    }
    
    func testConfimAPDUNoClient() {
        let commit = mockModels.getAPDUCommit()
        commit?.payload = mockModels.getPayload()
        commit?.payload?.apduPackage = mockModels.getApduPackage()
        
        commit?.confirmAPDU { (error) in
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testConfimAPDU() {
        let commit = mockModels.getAPDUCommit()
        commit?.payload = mockModels.getPayload()
        commit?.payload?.apduPackage = mockModels.getApduPackage()
        commit?.client = client
        
        commit?.confirmAPDU { (error) in
            expect(error).to(beNil())
        }
    }
    
}
