import XCTest
import Nimble

@testable import FitpaySDK

class SyncRequestsQueueTests: XCTestCase {
    var requestsQueue: SyncRequestQueue!
    var mockSyncManager: MockSyncManager!
    
    override func setUp() {
        super.setUp()
        
        MockSyncManager.syncCompleteDelay = 0.02
        
        self.mockSyncManager = MockSyncManager()
        self.requestsQueue = SyncRequestQueue(syncManager: self.mockSyncManager)
    }
    
    func testMake1SuccessSync() {
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testMake1FailedSync() {
        self.requestsQueue = SyncRequestQueue(syncManager: MockFailedSyncManger())
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                
                done()
            }
        }
        
    }
    
    func testSuccessQueueOrder() {
        var counter = 0
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
                
                done()
            }
        }
        
    }
    
    func testFailedQueueOrder() {
        self.requestsQueue = SyncRequestQueue(syncManager: MockFailedSyncManger())
        var counter = 0

        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                counter += 1
                
                done()
            }
        }
    }
    
    func testQueueOrderWithAsyncInsert() {
        var counter = 0
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
                
                self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                    expect(counter).to(equal(3))
                    expect(status).to(equal(.success))
                    expect(error).to(beNil())
                    counter += 1
                    
                    done()
                }
            }
            
            self.requestsQueue.add(request: SyncRequest()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
        }
    }
    
    func testParallelSync() {
        mockSyncManager.synchronousModeOn = false
        var counter = 0
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest2()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest2()) { (status, error) in
                expect(counter).to(equal(3))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
                done()
            }
        }
        
        
    }
    
    func testMakeSyncWithoutDeviceInfo() {
        mockSyncManager.synchronousModeOn = true
        SyncRequest.syncManager = self.mockSyncManager
        
        let request = SyncRequest()
        
        waitUntil { done in
            self.requestsQueue.add(request: request) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                done()
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getSyncRequest1() -> SyncRequest {
        let deviceInfo = Device()
        deviceInfo.deviceIdentifier = "111-111-111"
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: PaymentDevice())
        SyncRequest.syncManager = self.mockSyncManager
        return request
    }
    
    private func getSyncRequest2() -> SyncRequest {
        let deviceInfo = Device()
        deviceInfo.deviceIdentifier = "123-123-123"
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: PaymentDevice())
        SyncRequest.syncManager = self.mockSyncManager
        return request
    }
}
