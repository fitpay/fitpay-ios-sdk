import XCTest
import RxSwift

@testable import FitpaySDK

class SyncManagerTests: XCTestCase {
    
    var syncManager: SyncManager!
    var syncQueue: SyncRequestQueue!
    var fetcher: SyncMockCommitsFetcher!
    
    override func setUp() {
        super.setUp()
        
        fetcher = SyncMockCommitsFetcher()
        let syncFactory = SyncManagerTests.MocksFactory()
        syncFactory.commitsFetcher = fetcher
        syncManager = SyncManager(syncFactory: syncFactory)
        syncQueue = SyncRequestQueue(syncManager: syncManager)
    }

    func testMake1SuccessfullSync() {
        let expectation = super.expectation(description: "making 1 successfull sync")
        
        fetcher.commits = [fetcher.getAPDUCommit(), fetcher.getCreateCardCommit()]
        
        self.syncQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testMakeSyncWithEmptySyncRequestWhenAlreadySyncing() {
        let expectation = super.expectation(description: "Making sync with empty sync request when already syncing")
        var fetchesDuring1Sync = 0
        var isFirstSync = true
        fetcher.onStart = {
            fetchesDuring1Sync += 1
            XCTAssert(fetchesDuring1Sync == 1, "During ONE sync we should fetch commits only once")
            if isFirstSync {
                self.syncQueue.add(request: SyncRequest()) { (status, error) in
                    XCTAssertEqual(status, .success)
                    XCTAssertNil(error)
                    
                    expectation.fulfill()
                }
            }
            isFirstSync = false
        }
        
        fetcher.commits = [fetcher.getAPDUCommit()]
        
        self.syncQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            fetchesDuring1Sync = 0
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testMakeSyncWhenAlreadySyncing() {
        let expectation = super.expectation(description: "Making sync when already syncing")
        var fetchesDuring1Sync = 0
        var isFirstSync = true
        fetcher.onStart = {
            fetchesDuring1Sync += 1
            XCTAssert(fetchesDuring1Sync == 1, "During ONE sync we should fetch commits only once")
            if isFirstSync {
                self.syncQueue.add(request: self.getSyncRequest1()) { (status, error) in
                    XCTAssertEqual(status, .success)
                    XCTAssertNil(error)
                    
                    expectation.fulfill()
                }
            }
            isFirstSync = false
        }
        
        fetcher.commits = [fetcher.getAPDUCommit()]
        
        self.syncQueue.add(request: getSyncRequest1()) { (status, error) in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)
            fetchesDuring1Sync = 0
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testMakeFirstSyncWithEmptySyncRequest() {
        let expectation = super.expectation(description: "making first sync with empty sync request")
        
        fetcher.commits = [fetcher.getAPDUCommit()]
        
        self.syncQueue.add(request: SyncRequest()) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            XCTAssertNotNil(error as? SyncRequestQueue.SyncRequestQueueError)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testCheckDissconnectHandlerDuringAPDUExecution() {
        let expectation = super.expectation(description: "")
        
        fetcher.commits = [fetcher.getAPDUCommit()]
        let device = PaymentDevice()
        let connector = MockPaymentDeviceConnectorWithAPDUDisconnects(paymentDevice: device)
        connector.connectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.01
        connector.disconnectDelayTime = 0.2
        _ = device.changeDeviceInterface(connector)
        
        self.syncQueue.add(request: getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code, PaymentDevice.ErrorCode.deviceWasDisconnected.rawValue)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testCheckDissconnectHandlerDuringNonAPDUExecution() {
        let expectation = super.expectation(description: "")
        
        fetcher.commits = [fetcher.getCreateCardCommit()]
        
        let device = PaymentDevice()
        let connector = MockPaymentDeviceConnectorWithNonAPDUDisconnects(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        self.syncQueue.add(request: getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code, PaymentDevice.ErrorCode.nonApduProcessingTimeout.rawValue)
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testAPDUSyncTwoTimesWhenFirstWasFailedBecauseDeviceDisconnected() {
        let expectation = super.expectation(description: "")
        
        fetcher.commits = [fetcher.getAPDUCommit()]
        
        let device = PaymentDevice()
        let connector = MockPaymentDeviceConnectorWithAPDUDisconnects(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.apduExecuteDelayTime = 0.01
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        var isFirstSync = true
        fetcher.onStart = {
            if isFirstSync {
                self.syncQueue.add(request: self.getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
                    XCTAssertEqual(status, .success)
                    XCTAssertNil(error)
                    
                    expectation.fulfill()
                }
            }
            isFirstSync = false
        }
        
        self.syncQueue.add(request: getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code, PaymentDevice.ErrorCode.deviceWasDisconnected.rawValue)
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSyncAPDUTimeoutTest() {
        let expectation = super.expectation(description: "")
        
        fetcher.commits = [fetcher.getAPDUCommit()]
        
        let device = PaymentDevice()
        let connector = TimeoutedMockPaymentDeviceConnector(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        FitpaySDKConfiguration.defaultConfiguration.commitProcessingTimeoutSecs = 0.2
        
        self.syncQueue.add(request: getSyncRequest1(device: device)) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code, PaymentDevice.ErrorCode.apduSendingTimeout.rawValue)
            FitpaySDKConfiguration.defaultConfiguration.commitProcessingTimeoutSecs = 30 // return to default state
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSyncNonAPDUTimeoutTest() {
        let expectation = super.expectation(description: "")
        
        fetcher.commits = [fetcher.getCreateCardCommit()]
        
        let device = PaymentDevice()
        let connector = TimeoutedMockPaymentDeviceConnector(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        FitpaySDKConfiguration.defaultConfiguration.commitProcessingTimeoutSecs = 0.2
        
        self.syncQueue.add(request: getSyncRequest1(device: device)) { (status, error) in
            XCTAssertEqual(status, .failed)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code, PaymentDevice.ErrorCode.nonApduProcessingTimeout.rawValue)
            FitpaySDKConfiguration.defaultConfiguration.commitProcessingTimeoutSecs = 30 // return to default state
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
}

// Helpers
extension SyncManagerTests {
    func getSyncRequest1(device passedDevice: PaymentDevice? = nil) -> SyncRequest {
        let deviceInfo = DeviceInfo()
        deviceInfo.deviceIdentifier = "111-111-111"
        let device: PaymentDevice
        if passedDevice == nil {
            device = PaymentDevice()
            let mockConnector = MockPaymentDeviceConnector(paymentDevice: device)
            mockConnector.connectDelayTime = 0.1
            mockConnector.apduExecuteDelayTime = 0.01
            mockConnector.paymentDevice = device
            let _ = device.changeDeviceInterface(mockConnector)
        } else {
            device = passedDevice!
        }
        
        let request = SyncRequest(user: User(JSONString: "{\"id\":\"1\"}")!, deviceInfo: deviceInfo, paymentDevice: device)
        SyncRequest.syncManager = self.syncManager
        return request
    }
    
}

// Mocks
extension SyncManagerTests {
    class MocksFactory: SyncFactory {
        var commitsFetcher: FetchCommitsOperationProtocol!
        
        func apduConfirmOperation() -> APDUConfirmOperationProtocol {
            return MockAPDUConfirm()
        }
        
        func nonApduConfirmOperation() -> NonAPDUConfirmOperationProtocol {
            return MockNonAPDUConfirm()
        }
        
        func commitsFetcherOperationWith(deviceInfo: DeviceInfo, connector: IPaymentDeviceConnector?) -> FetchCommitsOperationProtocol {
            return commitsFetcher
        }
    }
    
    class SyncMockCommitsFetcher: MockCommitsFetcher {
        
        var onStart: () -> () = {
            
        }
        
        override func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]> {
            self.onStart()
            return Observable<[Commit]>.just(commits)
        }
    }
    
    class MockPaymentDeviceConnectorWithAPDUDisconnects: MockPaymentDeviceConnector {
        var apduProcessedCounter = 0
        var disconnectWhenApduProcessedCounterWillEqualTo = 3
        override func executeAPDUCommand(_ apduCommand: APDUCommand) {
            if !self.connected {
                return
            }
            
            if apduProcessedCounter >= disconnectWhenApduProcessedCounterWillEqualTo {
                self.disconnect()
                disconnectWhenApduProcessedCounterWillEqualTo = 20
                return
            }
            
            super.executeAPDUCommand(apduCommand)
            self.apduProcessedCounter += 1
        }
    }
    
    class MockPaymentDeviceConnectorWithNonAPDUDisconnects: MockPaymentDeviceConnector {
        func processNonAPDUCommit(_ commit: Commit, completion: @escaping (NonAPDUCommitState, NSError?) -> Void) {
            if !self.connected {
                return
            }
            
            self.disconnect()
        }
    }
    
    class TimeoutedMockPaymentDeviceConnector: MockPaymentDeviceConnector {
        override func executeAPDUCommand(_ apduCommand: APDUCommand) {
        }
        
        func processNonAPDUCommit(_ commit: Commit, completion: @escaping (NonAPDUCommitState, NSError?) -> Void) {
        }
    }
}




