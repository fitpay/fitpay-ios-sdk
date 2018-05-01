import XCTest
@testable import FitpaySDK

class MockSyncManager: SyncManagerProtocol {
    var synchronousModeOn: Bool = true
    var isSyncing: Bool = false
    
    static var syncCompleteDelay: Double = 0.2
    
    private let eventsDispatcher = FitpayEventDispatcher()
    
    private var lastSyncRequest: SyncRequest?
    
    func syncWith(request: SyncRequest) throws {
        if isSyncing && synchronousModeOn {
            throw NSError.unhandledError(MockSyncManager.self)
        }
        
        lastSyncRequest = request
        
        self.startSync(request: request)
    }
    
    func syncWithLastRequest() throws {
        guard let lastSyncRequest = self.lastSyncRequest else {
            throw NSError.unhandledError(MockSyncManager.self)
        }
        
        if isSyncing && synchronousModeOn {
            throw NSError.unhandledError(MockSyncManager.self)
        }
        
        self.startSync(request: lastSyncRequest)
    }
    
    func bindToSyncEvent(eventType: SyncEventType, completion: @escaping SyncEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    func removeSyncBinding(binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    func callCompletionForSyncEvent(_ event: SyncEventType, params: [String: Any]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: params))
    }
    
    func startSync(request: SyncRequest) {
        self.isSyncing = true
        
        DispatchQueue.main.asyncAfter(deadline: self.delayForSync) { [weak self] in
            self?.isSyncing = false
            self?.callCompletionForSyncEvent(.syncCompleted, params: ["request":request])
        }
    }
    
    var delayForSync: DispatchTime {
        return .now() + MockSyncManager.syncCompleteDelay
    }
}

class MockFailedSyncManger: MockSyncManager {
    override func startSync(request: SyncRequest) {
        self.isSyncing = true
        
        DispatchQueue.main.asyncAfter(deadline: self.delayForSync) { [weak self] in
            self?.isSyncing = false
            self?.callCompletionForSyncEvent(.syncFailed, params: ["request":request, "error":NSError.unhandledError(MockFailedSyncManger.self)])
        }
    }
}


class SyncRequestsQueueTests: XCTestCase {
    var requestsQueue: SyncRequestQueue!
    var mockSyncManager: MockSyncManager!
    
    override func setUp() {
        super.setUp()
        if log.outputs.count == 0 {
            log.addOutput(output: ConsoleOutput())
        }
        self.mockSyncManager = MockSyncManager()
        self.requestsQueue = SyncRequestQueue(syncManager: self.mockSyncManager)
    }
    
    func getSyncRequest1() -> SyncRequest {
        let deviceInfo = DeviceInfo()
        deviceInfo.deviceIdentifier = "111-111-111"
        let request = SyncRequest(user: User(JSONString: "{\"id\":\"1\"}")!, deviceInfo: deviceInfo, paymentDevice: PaymentDevice())
        SyncRequest.syncManager = self.mockSyncManager
        return request
    }
    
    func getSyncRequest2() -> SyncRequest {
        let deviceInfo = DeviceInfo()
        deviceInfo.deviceIdentifier = "123-123-123"
        let request = SyncRequest(user: User(JSONString: "{\"id\":\"1\"}")!, deviceInfo: deviceInfo, paymentDevice: PaymentDevice())
        SyncRequest.syncManager = self.mockSyncManager
        return request
    }
    
    func testMake1SuccessSync() {
        let expectation = super.expectation(description: "making 1 success sync")
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: MockSyncManager.syncCompleteDelay + 1, handler: nil)
    }
    
    func testMake1FailedSync() {
        
        self.requestsQueue = SyncRequestQueue(syncManager: MockFailedSyncManger())
        
        let expectation = super.expectation(description: "making 1 failed sync")
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: MockSyncManager.syncCompleteDelay + 1, handler: nil)
        
    }
    
    func testSuccessQueueOrder() {
        let expectation = super.expectation(description: "making success queue")
        
        MockSyncManager.syncCompleteDelay = 0.05
        
        var counter = 0
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 0)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 1)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 2)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
            
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: MockSyncManager.syncCompleteDelay * 3 + 1, handler: nil)
    }
    
    func testFailedQueueOrder() {
        self.requestsQueue = SyncRequestQueue(syncManager: MockFailedSyncManger())
        
        let expectation = super.expectation(description: "making failed queue")
        
        MockSyncManager.syncCompleteDelay = 0.02
        
        var counter = 0
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 0)
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 1)
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 2)
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            counter += 1
            
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: MockSyncManager.syncCompleteDelay * 3 + 1, handler: nil)
    }
    
    func testQueueOrderWithAsyncInsert() {
        let expectation = super.expectation(description: "making success queue")
        
        MockSyncManager.syncCompleteDelay = 0.02
        
        var counter = 0
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 0)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                XCTAssertEqual(counter, 3)
                XCTAssertEqual(status, .success)
                XCTAssertNil(error)
                counter += 1
                
                expectation.fulfill()
            }
        }
        
        self.requestsQueue.add(request: SyncRequest()) { (status, error) in
            XCTAssertEqual(counter, 1)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 2)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        super.waitForExpectations(timeout: MockSyncManager.syncCompleteDelay * 5 + 1, handler: nil)
    }
    
    func testParallelSync() {
        let expectation = super.expectation(description: "making parallel sync")
        
        mockSyncManager.synchronousModeOn = false
        MockSyncManager.syncCompleteDelay = 0.1
        
        var counter = 0
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 0)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(counter, 2)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest2()) { (status, error) in
            XCTAssertEqual(counter, 1)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
        }
        
        self.requestsQueue.add(request: getSyncRequest2()) { (status, error) in
            XCTAssertEqual(counter, 3)
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            counter += 1
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: MockSyncManager.syncCompleteDelay * 5 + 1, handler: nil)
    }
    
    func testMakeSyncWithoutDeviceInfo() {
        let expectation = super.expectation(description: "making sync without device info")
        mockSyncManager.synchronousModeOn = true
        SyncRequest.syncManager = self.mockSyncManager
        
        let request = SyncRequest()
        
        self.requestsQueue.add(request: request) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 1, handler: nil)
    }
}
