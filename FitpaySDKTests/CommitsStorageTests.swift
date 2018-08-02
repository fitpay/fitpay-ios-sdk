import XCTest
import RxSwift
@testable import FitpaySDK

class CommitsStorageTests: XCTestCase {
    var deviceInfo: Device!
    var paymentDevice: PaymentDevice!
    
    var disposeBag = DisposeBag()
    
    var syncManager: SyncManager!
    var syncQueue: SyncRequestQueue!
    var fetcher: MockCommitsFetcher!
    
    override func setUp() {
        super.setUp()
        
        deviceInfo = Device()
        deviceInfo.deviceIdentifier = "222-222-222"
        
        paymentDevice = PaymentDevice()
        
        fetcher = MockCommitsFetcher()
        let syncFactory = SyncManagerTests.MocksFactory()
        syncFactory.commitsFetcher = fetcher
        let syncStorage = MockSyncStorage.sharedMockInstance
        syncManager = SyncManager(syncFactory: syncFactory, syncStorage: syncStorage)
        syncQueue = SyncRequestQueue(syncManager: syncManager)
    }
    
    func testCheckLoadCommitIdFromDevice() {
        let expectation = super.expectation(description: "check load commitId from device")
        let connector = MockPaymentDeviceConnectorWithStorage(paymentDevice: self.paymentDevice)
        
        let fetch = FetchCommitsOperation(deviceInfo: self.deviceInfo,
                                          shouldStartFromSyncedCommit: true,
                                          syncStorage: MockSyncStorage.sharedMockInstance,
                                          connector: connector)
        
        fetch.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
            XCTAssertEqual(commitId, String())
            connector.setDeviceLastCommitId("123456")
            
            fetch.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
                XCTAssertEqual(commitId, "123456")
                
                expectation.fulfill()
            }).disposed(by: self.disposeBag)
            
        }).disposed(by: self.disposeBag)
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testCheckLoadCommitIdFromDeviceWithWrongStorage () {
        var step = 0
        
        let expectation = super.expectation(description: "check load commitId from device with wrong storage")
        
        let syncStorage = MockSyncStorage.sharedMockInstance
        let localCommitId = "654321"
        syncStorage.setLastCommitId(self.deviceInfo.deviceIdentifier!, commitId: localCommitId)
        let lastCommit = syncStorage.getLastCommitId(self.deviceInfo.deviceIdentifier!)
        XCTAssertEqual(lastCommit, localCommitId)
        
        let fetch1 = FetchCommitsOperation(deviceInfo: self.deviceInfo,
                                           shouldStartFromSyncedCommit: true,
                                           syncStorage: syncStorage,
                                           connector: MockPaymentDeviceConnectorWithWrongStorage1(paymentDevice: self.paymentDevice))
        
        fetch1.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
            XCTAssertEqual(commitId, localCommitId)
            step += 1
            if step == 2 {
                expectation.fulfill()
            }
        }).disposed(by: self.disposeBag)
        
        let fetch2 = FetchCommitsOperation(deviceInfo: self.deviceInfo,
                                           shouldStartFromSyncedCommit: true,
                                           syncStorage: syncStorage,
                                           connector: MockPaymentDeviceConnectorWithWrongStorage2(paymentDevice: self.paymentDevice))
        
        fetch2.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
            XCTAssertEqual(commitId, localCommitId)
            step += 1
            if step == 2 {
                expectation.fulfill()
            }
        }).disposed(by: self.disposeBag)
        
        super.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testCheckSavingCommitIdToDevice() {
        let expectation = super.expectation(description: "check commitId what must be saved on device")
        
        guard let commit = fetcher.getAPDUCommit() else { XCTAssert(false, "Bad parsing."); return }
        fetcher.commits = [commit]
        
        let connector = MockPaymentDeviceConnectorWithStorage(paymentDevice: self.paymentDevice)
        connector.connectDelayTime = 0.2
        connector.disconnectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.1
        
        self.syncQueue.add(request: getSyncRequest(connector: connector)) { (status, error) in
            let storedDeviceCommitId = connector.getDeviceLastCommitId()
            XCTAssertEqual(storedDeviceCommitId, "21321312")
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testCheckSavingCommitIdToPhone() {
        let expectation = super.expectation(description: "check commitId what must be saved on phone")
        
        guard let commit = fetcher.getAPDUCommit() else { XCTAssert(false, "Bad parsing."); return }
        fetcher.commits = [commit]
        
        let connector = MockPaymentDeviceConnectorWithWrongStorage1(paymentDevice: self.paymentDevice)
        connector.connectDelayTime = 0.2
        connector.disconnectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.1
        
        self.syncQueue.add(request: getSyncRequest(connector: connector)) { (status, error) in
            let storedDeviceCommitId = MockSyncStorage.sharedMockInstance.getLastCommitId(self.deviceInfo.deviceIdentifier!)
            XCTAssertEqual(storedDeviceCommitId, "21321312")
            expectation.fulfill()
        }
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
}

extension CommitsStorageTests { // Mocks
    class MockPaymentDeviceConnectorWithStorage: MockPaymentDeviceConnector {
        var commitId: String?
        
        func getDeviceLastCommitId() -> String {
            return commitId ?? String()
        }

        func setDeviceLastCommitId(_ commitId: String) {
            self.commitId = commitId
        }
    }
    
    class MockPaymentDeviceConnectorWithWrongStorage1: MockPaymentDeviceConnector {
        var commitId: String?
        
        func setDeviceLastCommitId(_ commitId: String) {
            self.commitId = commitId
        }
    }

    class MockPaymentDeviceConnectorWithWrongStorage2: MockPaymentDeviceConnector {
        var commitId: String?
        
        func getDeviceLastCommitId() -> String {
            return commitId ?? String()
        }
    }
    
    class MockSyncStorage: SyncStorage {
        public static let sharedMockInstance = MockSyncStorage()
        var commits =  [String: String]()
        
        override public func getLastCommitId(_ deviceId:String) -> String {
                return commits[deviceId] ?? String()
        }
        
        override public func setLastCommitId(_ deviceId:String, commitId:String) -> Void {
            commits[deviceId] = commitId
        }
    }
}

extension CommitsStorageTests { // Private Helplers
    
    private func getSyncRequest(connector: MockPaymentDeviceConnector) -> SyncRequest {
        let device = self.paymentDevice!
        let _ = device.changeDeviceInterface(connector)
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: device)
        SyncRequest.syncManager = self.syncManager
        return request
    }
    
}

