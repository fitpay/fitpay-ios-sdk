import XCTest
import Nimble
import RxSwift

@testable import FitpaySDK

class SyncManagerTests: XCTestCase {
    
    var syncManager: SyncManager!
    var syncQueue: SyncRequestQueue!
    var fetcher: SyncMockCommitsFetcher!
    
    override func setUp() {
        super.setUp()
        
        Nimble.AsyncDefaults.Timeout = 4
        
        fetcher = SyncMockCommitsFetcher()
        let syncFactory = SyncManagerTests.MocksFactory()
        syncFactory.commitsFetcher = fetcher
        syncManager = SyncManager(syncFactory: syncFactory)
        syncQueue = SyncRequestQueue(syncManager: syncManager)
    }

    func testMake1SuccessfullSync() {
        guard let commit1 = fetcher.getAPDUCommit(), let commit2 = fetcher.getCreateCardCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit1, commit2]
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testMakeSyncWithEmptySyncRequestWhenAlreadySyncing() {
        var fetchesDuring1Sync = 0
        var isFirstSync = true
        
        waitUntil { done in
            self.fetcher.onStart = {
                fetchesDuring1Sync += 1
                expect(fetchesDuring1Sync).to(equal(1))
                
                if isFirstSync {
                    self.syncQueue.add(request: SyncRequest()) { (status, error) in
                        expect(status).to(equal(.success))
                        expect(error).to(beNil())
                        done()
                    }
                }
                isFirstSync = false
            }
            
            guard let commit = self.fetcher.getAPDUCommit() else {
                fail("Bad parsing.")
                return
            }
            self.fetcher.commits = [commit]
            
            self.syncQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                fetchesDuring1Sync = 0
            }
        }
        
    }
    
    func testMakeSyncWhenAlreadySyncing() {
        var fetchesDuring1Sync = 0
        var isFirstSync = true
        
        waitUntil { done in
            self.fetcher.onStart = {
                fetchesDuring1Sync += 1
                expect(fetchesDuring1Sync).to(equal(1))
                if isFirstSync {
                    self.syncQueue.add(request: self.getSyncRequest1()) { (status, error) in
                        expect(status).to(equal(.success))
                        expect(error).to(beNil())
                        done()
                    }
                }
                isFirstSync = false
            }
            
            guard let commit = self.fetcher.getAPDUCommit() else {
                fail("Bad parsing.")
                return
            }
            self.fetcher.commits = [commit]
            
            self.syncQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                fetchesDuring1Sync = 0
            }
        }
    }
    
    func testMakeFirstSyncWithEmptySyncRequest() {
        guard let commit = self.fetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit]
        
        waitUntil { done in
            self.syncQueue.add(request: SyncRequest()) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error as? SyncRequestQueue.SyncRequestQueueError).toNot(beNil())
                done()
            }
        }
    }
    
    func testCheckDissconnectHandlerDuringAPDUExecution() {
        guard let commit = self.fetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit]
        
        let device = PaymentDevice()
        let connector = MockPaymentDeviceConnectorWithAPDUDisconnects(paymentDevice: device)
        connector.connectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.01
        connector.disconnectDelayTime = 0.2
        _ = device.changeDeviceInterface(connector)
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                expect((error as NSError?)?.code).to(equal(PaymentDevice.ErrorCode.deviceWasDisconnected.rawValue))
                done()
            }
        }
       
        
    }
    
    func testCheckDissconnectHandlerDuringNonAPDUExecution() {
        guard let commit = fetcher.getCreateCardCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit]
        
        let device = PaymentDevice()
        let connector = MockPaymentDeviceConnectorWithNonAPDUDisconnects(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                expect((error as NSError?)?.code).to(equal(PaymentDevice.ErrorCode.nonApduProcessingTimeout.rawValue))
                done()
            }
        }
    }
    
    func testAPDUSyncTwoTimesWhenFirstWasFailedBecauseDeviceDisconnected() {
        guard let commit = self.fetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit]
        
        let device = PaymentDevice()
        let connector = MockPaymentDeviceConnectorWithAPDUDisconnects(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.apduExecuteDelayTime = 0.01
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        var isFirstSync = true
        
        waitUntil { done in
            self.fetcher.onStart = {
                if isFirstSync {
                    self.syncQueue.add(request: self.getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
                        expect(status).to(equal(.success))
                        expect(error).to(beNil())
                        done()
                    }
                }
                isFirstSync = false
            }
            
            self.syncQueue.add(request: self.getSyncRequest1(device: connector.paymentDevice)) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                expect((error as NSError?)?.code).to(equal(PaymentDevice.ErrorCode.deviceWasDisconnected.rawValue))
            }
        }
    }
    
    func testSyncAPDUTimeoutTest() {
        guard let commit = self.fetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit]
        
        let device = PaymentDevice()
        let connector = TimeoutedMockPaymentDeviceConnector(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        device.commitProcessingTimeout = 0.2
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest1(device: device)) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                expect((error as NSError?)?.code).to(equal(PaymentDevice.ErrorCode.apduSendingTimeout.rawValue))
                done()
            }
        }
        
    }
    
    func testSyncNonAPDUTimeoutTest() {
        guard let commit = fetcher.getCreateCardCommit() else {
            fail("Bad parsing.")
            return
        }
        fetcher.commits = [commit]
        
        let device = PaymentDevice()
        let connector = TimeoutedMockPaymentDeviceConnector(paymentDevice: device)
        connector.connectDelayTime = 0.1
        connector.disconnectDelayTime = 0.1
        _ = device.changeDeviceInterface(connector)
        
        device.commitProcessingTimeout = 0.2
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest1(device: device)) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                expect((error as NSError?)?.code).to(equal(PaymentDevice.ErrorCode.nonApduProcessingTimeout.rawValue))
                done()
            }
        }
    }
}

// Helpers
extension SyncManagerTests {
    
    func getSyncRequest1(device passedDevice: PaymentDevice? = nil) -> SyncRequest {
        let deviceInfo = Device()
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
        
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: device)
        SyncRequest.syncManager = self.syncManager
        return request
    }
    
}

// MARK: -  Mocks

extension SyncManagerTests {
    
    class MocksFactory: SyncFactory {
        
        var commitsFetcher: FetchCommitsOperationProtocol!
        
        func apduConfirmOperation() -> APDUConfirmOperationProtocol {
            return MockAPDUConfirm()
        }
        
        func nonApduConfirmOperation() -> NonAPDUConfirmOperationProtocol {
            return MockNonAPDUConfirm()
        }
        
        func commitsFetcherOperationWith(deviceInfo: Device, connector: PaymentDeviceConnectable?) -> FetchCommitsOperationProtocol {
            return commitsFetcher
        }
    
    }
    
    class SyncMockCommitsFetcher: MockCommitsFetcher {
        
        var onStart: () -> () = {
            
        }
        
        override func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]> {
            onStart()
            return Observable<[Commit]>.just(commits)
        }
    
    }
    
    class MockPaymentDeviceConnectorWithAPDUDisconnects: MockPaymentDeviceConnector {
        var apduProcessedCounter = 0
        var disconnectWhenApduProcessedCounterWillEqualTo = 3
       
        override func executeAPDUCommand(_ apduCommand: APDUCommand) {
            if !self.connected { return }
            
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
            if !self.connected { return }
            
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

