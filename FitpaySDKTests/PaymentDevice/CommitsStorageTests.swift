import XCTest
import Nimble
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
        
        Nimble.AsyncDefaults.Timeout = 4
        
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
        let connector = MockPaymentDeviceConnectorWithStorage(paymentDevice: self.paymentDevice)
        
        let fetch = FetchCommitsOperation(deviceInfo: self.deviceInfo,
                                          shouldStartFromSyncedCommit: true,
                                          syncStorage: MockSyncStorage.sharedMockInstance,
                                          connector: connector)
        
        waitUntil { done in
            fetch.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
                expect(commitId).to(equal(String()))
                connector.setDeviceLastCommitId("123456")
                
                fetch.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
                    expect(commitId).to(equal("123456"))
                    
                    done()
                }).disposed(by: self.disposeBag)
                
            }).disposed(by: self.disposeBag)
        }
        
    }
    
    func testCheckLoadCommitIdFromDeviceWithWrongStorage () {
        var step = 0
        let syncStorage = MockSyncStorage.sharedMockInstance
        let localCommitId = "654321"
        
        syncStorage.setLastCommitId(self.deviceInfo.deviceIdentifier!, commitId: localCommitId)
        
        let lastCommit = syncStorage.getLastCommitId(self.deviceInfo.deviceIdentifier!)
        
        expect(lastCommit).to(equal(localCommitId))
        
        let fetch1 = FetchCommitsOperation(deviceInfo: self.deviceInfo,
                                           shouldStartFromSyncedCommit: true,
                                           syncStorage: syncStorage,
                                           connector: MockPaymentDeviceConnectorWithWrongStorage1(paymentDevice: self.paymentDevice))
        
        let fetch2 = FetchCommitsOperation(deviceInfo: self.deviceInfo,
                                           shouldStartFromSyncedCommit: true,
                                           syncStorage: syncStorage,
                                           connector: MockPaymentDeviceConnectorWithWrongStorage2(paymentDevice: self.paymentDevice))
        
        waitUntil { done in
            fetch1.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
                expect(commitId).to(equal(localCommitId))
                step += 1
                if step == 2 {
                    done()
                }
            }).disposed(by: self.disposeBag)
            
            fetch2.generateCommitIdFromWhichWeShouldStart().subscribe(onNext: { (commitId) in
                expect(commitId).to(equal(localCommitId))
                step += 1
                if step == 2 {
                    done()
                }
            }).disposed(by: self.disposeBag)
        }

    }
    
    func testCheckSavingCommitIdToDevice() {
        guard let commit = fetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        
        fetcher.commits = [commit]
        
        let connector = MockPaymentDeviceConnectorWithStorage(paymentDevice: self.paymentDevice)
        connector.connectDelayTime = 0.2
        connector.disconnectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.1
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest(connector: connector)) { (_, _) in
                let storedDeviceCommitId = connector.getDeviceLastCommitId()
                expect(storedDeviceCommitId).to(equal("21321312"))
                done()
            }
        }
        
    }
    
    func testCheckSavingCommitIdToPhone() {
        guard let commit = fetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        
        fetcher.commits = [commit]
        
        let connector = MockPaymentDeviceConnectorWithWrongStorage1(paymentDevice: self.paymentDevice)
        connector.connectDelayTime = 0.2
        connector.disconnectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.1
        
        waitUntil { done in
            self.syncQueue.add(request: self.getSyncRequest(connector: connector)) { (_, _) in
                let storedDeviceCommitId = MockSyncStorage.sharedMockInstance.getLastCommitId(self.deviceInfo.deviceIdentifier!)
                expect(storedDeviceCommitId).to(equal("21321312"))
                done()
            }
        }
        
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
        
        override public func getLastCommitId(_ deviceId: String) -> String {
            return commits[deviceId] ?? String()
        }
        
        override public func setLastCommitId(_ deviceId: String, commitId: String) {
            commits[deviceId] = commitId
        }
    }
}

extension CommitsStorageTests { // Private Helpers
    
    private func getSyncRequest(connector: MockPaymentDeviceConnector) -> SyncRequest {
        let device = self.paymentDevice!
        _ = device.changeDeviceInterface(connector)
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: device)
        SyncRequest.syncManager = self.syncManager
        return request
    }
    
}
