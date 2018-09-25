import XCTest
import Nimble
import RxSwift
import RxBlocking

@testable import FitpaySDK

class SyncOperationTests: XCTestCase {
    var syncOperation: SyncOperation!
    var commitsFetcher = MockCommitsFetcher()
    var mocksFactory = MockSyncFactory()
    var connector: MockPaymentDeviceConnector!
    
    var disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        Nimble.AsyncDefaults.Timeout = 4
        
        disposeBag = DisposeBag()
        
        mocksFactory.commitsFetcher = commitsFetcher
        
        let paymentDevice = PaymentDevice()
        connector = MockPaymentDeviceConnector(paymentDevice: paymentDevice)
        connector.connectDelayTime = 0.001
        connector.apduExecuteDelayTime = 0.01
        _ = paymentDevice.changeDeviceInterface(connector)

        syncOperation = SyncOperation(paymentDevice: paymentDevice, connector: connector, deviceInfo: Device(), user: try! User("{\"id\":\"1\"}"), syncFactory: mocksFactory, syncRequest: SyncRequest())
    }
    
    func testSuccessfullSyncWithoutCommits() {
        commitsFetcher.commits = []
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            fail("Timeouted.")
            return
        }
        expect(events.last?.event).to(equal(SyncEventType.syncCompleted))
    }
    
    func testSuccessfullSyncWithAddCardCommits() {
        guard let commit = commitsFetcher.getCreateCardCommit(id: "123213213") else {
            fail("Bad parsing.")
            return
        }
        commitsFetcher.commits = [commit]
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            fail("Timeouted.")
            return
        }
        expect(events.contains { $0.event == SyncEventType.cardAdded }).to(beTrue())
        expect(events.last?.event).to(equal(SyncEventType.syncCompleted))
    }
    
    func testSuccessSyncWithAPDUCommit() {
        guard let commit = commitsFetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        
        commitsFetcher.commits = [commit]
        syncOperation.commitsApplyer.apduConfirmOperation = MockAPDUConfirm()
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            fail("Timeouted.")
            return
        }
        events.forEach { print("Event: \($0.event.eventDescription()), data: \($0.data)") }
        expect(events.contains { $0.event == SyncEventType.apduPackageComplete }).to(beTrue())
        expect(events.last?.event).to(equal(SyncEventType.syncCompleted))
    }
    
    func testSuccessSyncWithAPDUAndNonAPDUCommits() {
        guard let commit1 = commitsFetcher.getCreateCardCommit(id: "1"), let commit2 = commitsFetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        commitsFetcher.commits = [commit1, commit2]
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            fail("Timeouted.")
            return
        }
        events.forEach { print("Event: \($0.event.eventDescription()), data: \($0.data)") }
        expect(events.contains { $0.event == SyncEventType.apduPackageComplete }).to(beTrue())
        expect(events.contains { $0.event == SyncEventType.cardAdded }).to(beTrue())
        expect(events.last?.event).to(equal(SyncEventType.syncCompleted))
    }
    
    func testParallelSync() {
        let paymentDevice = PaymentDevice()
        let secondConnector = MockPaymentDeviceConnector(paymentDevice: paymentDevice)
        _ = paymentDevice.changeDeviceInterface(secondConnector)
        
        let secondSyncOperation = SyncOperation(paymentDevice: paymentDevice, connector: secondConnector, deviceInfo: Device(), user: try! User("{\"id\":\"1\"}"), syncFactory: mocksFactory, syncRequest: SyncRequest())
        guard let commit1 = commitsFetcher.getCreateCardCommit(id: "1"), let commit2 = commitsFetcher.getAPDUCommit() else {
            fail("Bad parsing.")
            return
        }
        commitsFetcher.commits = [commit1, commit2]
        
        secondConnector.connectDelayTime = 0.1 // second operation should work faster
        secondConnector.apduExecuteDelayTime = 0.01
        connector.connectDelayTime = 0.3
        connector.apduExecuteDelayTime = 0.01
        
        var syncCompleteCounter = 0
        
        waitUntil { done in
            self.syncOperation.start().subscribe(onNext: { (event) in
                if event.event == .syncCompleted {
                    expect(syncCompleteCounter).to(equal(1))
                    done()
                }
            }).disposed(by: self.disposeBag)
            
            secondSyncOperation.start().subscribe(onNext: { (event) in
                if event.event == .syncCompleted {
                    syncCompleteCounter += 1
                }
            }).disposed(by: self.disposeBag)
        }
        
    }
    
    func testSyncWithUnknownCommitType() {
        guard let commit1 = commitsFetcher.getCreateCardCommit(id: "1"), let commit2 = commitsFetcher.getUnknownCommitType() else {
            fail("Bad parsing.")
            return
        }
        commitsFetcher.commits = [commit1, commit2]
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            fail("Timeouted.")
            return
        }
        
        events.forEach { print("Event: \($0.event.eventDescription()), data: \($0.data)") }
        
        expect(events.contains { $0.event == SyncEventType.cardAdded }).to(beTrue())
        expect(events.last?.event).to(equal(SyncEventType.syncCompleted))
    }
}
