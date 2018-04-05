import XCTest
import RxSwift
import RxBlocking

@testable import FitpaySDK

class MockAPDUConfirm: APDUConfirmOperationProtocol {
    func startWith(commit: Commit) -> Observable<Void> {
        return Observable.empty()
    }
}

class MockNonAPDUConfirm: NonAPDUConfirmOperationProtocol {
    func startWith(commit: Commit, result: NonAPDUCommitState) -> Observable<Void> {
        return Observable.empty()
    }
}

class MockCommitsFetcher: FetchCommitsOperationProtocol {
    var deviceInfo: DeviceInfo!
    
    var commits: [Commit] = []
    
    func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]> {
        return Observable<[Commit]>.just(commits)
    }
    
    func getCreateCardCommit(id: String = "12323") -> Commit {
        return Commit(JSONString: "{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"commitType\":\"CREDITCARD_CREATED\",\"payload\":{\"createdTsEpoch\":1446587257324,\"cvv\":\"###\",\"address\":{\"street1\":\"1035 Pearl St\",\"street2\":\"5th Floor\",\"city\":\"Boulder\",\"state\":\"CO\",\"postalCode\":\"80302\",\"countryCode\":\"US\"},\"deviceRelationships\":[{\"deviceType\":\"ACTIVITY_TRACKER\",\"deviceIdentifier\":\"677af018-01b1-47d9-9b08-0c18d89aa2e3\",\"manufacturerName\":\"Pebble\",\"deviceName\":\"Pebble Time\",\"serialNumber\":\"074DCC022E14\",\"modelNumber\":\"FB404\",\"hardwareRevision\":\"1.0.0.0\",\"firmwareRevision\":\"1030.6408.1309.0001\",\"softwareRevision\":\"2.0.242009.6\",\"createdTs\":\"2015-11-03T21:47:37.146+0000\",\"createdTsEpoch\":1446587257146,\"osName\":\"ANDROID\",\"systemId\":\"0x123456FFFE9ABCDE\"}],\"cardType\":\"VISA\",\"creditCardId\":\"da635517-7f9e-4833-a772-2eab3b9d30c9\",\"termsAssetId\":\"c076a474-222c-48f4-9f87-776ee2cb0140\",\"userId\":\"9469bfe0-3fa1-4465-9abf-f78cacc740b2\",\"createdTs\":\"2015-11-03T21:47:37.324Z\",\"expMonth\":12,\"targetDeviceType\":\"fitpay.tokenization.model.Device\",\"expYear\":2018,\"targetDeviceId\":\"677af018-01b1-47d9-9b08-0c18d89aa2e3\",\"termsAssetReferences\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-498647650&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=40\",\"title\":null}},\"mimeType\":\"text/html\"}],\"name\":\"John Doe\",\"state\":\"ELIGIBLE\",\"pan\":\"############4441\",\"cardMetaData\":{\"labelColor\":\"00000\",\"issuerName\":\"JPMorgan Chase\",\"shortDescription\":\"Chase Freedom Visa\",\"longDescription\":\"Chase Freedom Visa with the super duper rewards\",\"contactUrl\":\"www.chase.com\",\"contactPhone\":\"18001234567\",\"contactEmail\":\"goldcustomer@chase.com\",\"termsAndConditionsUrl\":\"http://visa.com/terms\",\"privacyPolicyUrl\":\"http://visa.com/privacy\",\"brandLogo\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-210715922&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"20\",\"width\":\"60\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-905912687&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"58\",\"width\":\"180\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-1988261446&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"32\",\"width\":\"100\"}],\"cardBackground\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-2027889239&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=42\",\"title\":null}},\"mimeType\":\"image/png\",\"height\":\"184\",\"width\":\"275\"}],\"cardBackgroundCombined\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-2027889239&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=43\",\"title\":null}},\"mimeType\":\"image/png\",\"height\":\"184\",\"width\":\"275\"}],\"icon\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=1661540331&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=2\",\"title\":null}},\"mimeType\":\"image/jpeg\",\"height\":\"1024\",\"width\":\"1024\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-1279887808&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=2\",\"title\":null}},\"mimeType\":\"image/png\",\"height\":\"64\",\"width\":\"64\"}],\"issuerLogo\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-210715922&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"20\",\"width\":\"60\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-905912687&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"58\",\"width\":\"180\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-1988261446&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"32\",\"width\":\"100\"}]}},\"createdTs\":1446587258151,\"commit\":\"\(id)\"}")!
    }
    
    func getAPDUCommit() -> Commit {
        let commit = Commit(JSONString: "{\"commitType\":\"APDU_PACKAGE\"}")!
        commit.payload = Payload(JSONString: "{\"seIdType\":\"cplc\",\"targetDeviceType\":\"fitpay.gandd.model.Device\",\"targetDeviceId\":\"74534d29-d23d-4f6e-a306-679edc080915\",\"packageId\":\"baff97fb-0b73-5019-8877-7c490a43dc64\",\"seId\":\"274689f09352405792e9493356ac880c4444444\",\"targetAid\":\"8050200008CF0AFB2A88611AD51C\",\"commandApdus\":[{\"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d513\",\"groupId\":0,\"sequence\":0,\"command\":\"00DA1234567890\",\"type\":\"PUT_DATA\"},{\"commandId\":\"239ec5db-a19a-4813-ab4c-471dacc726ee\",\"groupId\":1,\"sequence\":1,\"command\":\"8050200008CF0AFB2A88611AD51C\",\"type\":\"UNKNOWN\"},{\"commandId\":\"445c3aec-22c7-41fe-a0ef-eee48bf8801c\",\"groupId\":1,\"sequence\":2,\"command\":\"84820300106BBC29E6A224522E83A9B26FD456111500\",\"type\":\"UNKNOWN\"},{\"commandId\":\"3abec35d-ed88-4d2c-ae09-442aee51ffac\",\"groupId\":1,\"sequence\":3,\"command\":\"84F2200210F25397DCFB728E25FBEE52E748A116A800\",\"type\":\"UNKNOWN\"},{\"commandId\":\"c8246e40-98df-45da-9906-78cb87ae6253\",\"groupId\":2,\"sequence\":4,\"command\":\"84F2200210F25397DCFB728E25FBEE52E748A116A800\",\"type\":\"UNKNOWN\"},{\"commandId\":\"2fc6b4eb-9fdb-4df6-a7f8-d4d9d407d673\",\"groupId\":3,\"sequence\":5,\"command\":\"84F2200210F25397DCFB728E25FBEE52E748A116A800\",\"type\":\"UNKNOWN\"}],\"validUntil\":\"2030-12-11T21:22:58.691Z\",\"packageType\":\"NORMAL\",\"apduPackageUrl\":\"http://localhost:9103/transportservice/v1/apdupackages/baff97fb-0b73-5019-8877-7c490a43dc64\"}")
        commit.commit = "21321312"
        return commit
    }
    
    func getUnknownCommitType() -> Commit {
        return Commit(JSONString: "{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"commitType\":\"NOT_EXIST\",\"payload\":{\"createdTsEpoch\":1446587257324,\"cvv\":\"###\",\"address\":{\"street1\":\"1035 Pearl St\",\"street2\":\"5th Floor\",\"city\":\"Boulder\",\"state\":\"CO\",\"postalCode\":\"80302\",\"countryCode\":\"US\"},\"deviceRelationships\":[{\"deviceType\":\"ACTIVITY_TRACKER\",\"deviceIdentifier\":\"677af018-01b1-47d9-9b08-0c18d89aa2e3\",\"manufacturerName\":\"Pebble\",\"deviceName\":\"Pebble Time\",\"serialNumber\":\"074DCC022E14\",\"modelNumber\":\"FB404\",\"hardwareRevision\":\"1.0.0.0\",\"firmwareRevision\":\"1030.6408.1309.0001\",\"softwareRevision\":\"2.0.242009.6\",\"createdTs\":\"2015-11-03T21:47:37.146+0000\",\"createdTsEpoch\":1446587257146,\"osName\":\"ANDROID\",\"systemId\":\"0x123456FFFE9ABCDE\"}],\"cardType\":\"VISA\",\"creditCardId\":\"da635517-7f9e-4833-a772-2eab3b9d30c9\",\"termsAssetId\":\"c076a474-222c-48f4-9f87-776ee2cb0140\",\"userId\":\"9469bfe0-3fa1-4465-9abf-f78cacc740b2\",\"createdTs\":\"2015-11-03T21:47:37.324Z\",\"expMonth\":12,\"targetDeviceType\":\"fitpay.tokenization.model.Device\",\"expYear\":2018,\"targetDeviceId\":\"677af018-01b1-47d9-9b08-0c18d89aa2e3\",\"termsAssetReferences\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-498647650&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=40\",\"title\":null}},\"mimeType\":\"text/html\"}],\"name\":\"John Doe\",\"state\":\"ELIGIBLE\",\"pan\":\"############4441\",\"cardMetaData\":{\"labelColor\":\"00000\",\"issuerName\":\"JPMorgan Chase\",\"shortDescription\":\"Chase Freedom Visa\",\"longDescription\":\"Chase Freedom Visa with the super duper rewards\",\"contactUrl\":\"www.chase.com\",\"contactPhone\":\"18001234567\",\"contactEmail\":\"goldcustomer@chase.com\",\"termsAndConditionsUrl\":\"http://visa.com/terms\",\"privacyPolicyUrl\":\"http://visa.com/privacy\",\"brandLogo\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-210715922&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"20\",\"width\":\"60\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-905912687&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"58\",\"width\":\"180\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-1988261446&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"32\",\"width\":\"100\"}],\"cardBackground\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-2027889239&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=42\",\"title\":null}},\"mimeType\":\"image/png\",\"height\":\"184\",\"width\":\"275\"}],\"cardBackgroundCombined\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-2027889239&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=43\",\"title\":null}},\"mimeType\":\"image/png\",\"height\":\"184\",\"width\":\"275\"}],\"icon\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=1661540331&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=2\",\"title\":null}},\"mimeType\":\"image/jpeg\",\"height\":\"1024\",\"width\":\"1024\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-1279887808&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=2\",\"title\":null}},\"mimeType\":\"image/png\",\"height\":\"64\",\"width\":\"64\"}],\"issuerLogo\":[{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-210715922&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"20\",\"width\":\"60\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-905912687&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"58\",\"width\":\"180\"},{\"_links\":{\"self\":{\"rel\":\"self\",\"href\":\"https://api.fit-pay.com/assets?assetId=-1988261446&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=41\",\"title\":null}},\"mimeType\":\"image/gif\",\"height\":\"32\",\"width\":\"100\"}]}},\"createdTs\":1446587258151,\"commit\":\"1\"}")!
    }
}

class MocksFactory: SyncFactory {
    var commitsFetcher: MockCommitsFetcher!
    
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

let log = FitpaySDKLogger.sharedInstance

class SyncOperationTests: XCTestCase {
    var syncOperation: SyncOperation!
    var commitsFetcher = MockCommitsFetcher()
    var mocksFactory = MocksFactory()
    var connector: MockPaymentDeviceConnector!
    
    var disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        if log.outputs.count == 0 {
            log.addOutput(output: ConsoleOutput())
        }
        log.minLogLevel = .debug
        
        disposeBag = DisposeBag()
        
        mocksFactory.commitsFetcher = commitsFetcher
        
        let paymentDevice = PaymentDevice()
        connector = MockPaymentDeviceConnector(paymentDevice: paymentDevice)
        connector.apduExecuteDelayTime = 0.01
        _ = paymentDevice.changeDeviceInterface(connector)
        
        syncOperation = SyncOperation(paymentDevice: paymentDevice, connector: connector, deviceInfo: DeviceInfo(), user: User(JSONString: "{\"id\":\"1\"}")!, syncFactory: mocksFactory)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccessfullSyncWithoutCommits() {
        connector.connectDelayTime = 0.001
        commitsFetcher.commits = []
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            XCTAssert(false, "Timeouted.")
            return
        }
        XCTAssertEqual(events.last?.event, SyncEventType.syncCompleted)
    }
    
    func testSuccessfullSyncWithAddCardCommits() {
        connector.connectDelayTime = 0.001
        commitsFetcher.commits = [commitsFetcher.getCreateCardCommit(id: "123213213")]
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            XCTAssert(false, "Timeouted.")
            return
        }
        XCTAssertTrue(events.contains { $0.event == SyncEventType.cardAdded })
        XCTAssertEqual(events.last?.event, SyncEventType.syncCompleted)
    }
    
    func testSuccessSyncWithAPDUCommit() {
        connector.connectDelayTime = 0.001
        commitsFetcher.commits = [commitsFetcher.getAPDUCommit()]
        syncOperation.commitsApplyer.apduConfirmOperation = MockAPDUConfirm()
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            XCTAssert(false, "Timeouted.")
            return
        }
        events.forEach{ print("Event: \($0.event.eventDescription()), data: \($0.data)") }
        XCTAssertTrue(events.contains { $0.event == SyncEventType.apduPackageComplete })
        XCTAssertEqual(events.last?.event, SyncEventType.syncCompleted)
    }
    
    func testSuccessSyncWithAPDUAndNonAPDUCommits() {
        connector.connectDelayTime = 0.001
        commitsFetcher.commits = [commitsFetcher.getCreateCardCommit(id: "1"), commitsFetcher.getAPDUCommit()]
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            XCTAssert(false, "Timeouted.")
            return
        }
        events.forEach{ print("Event: \($0.event.eventDescription()), data: \($0.data)") }
        XCTAssertTrue(events.contains { $0.event == SyncEventType.apduPackageComplete })
        XCTAssertTrue(events.contains { $0.event == SyncEventType.cardAdded })
        XCTAssertEqual(events.last?.event, SyncEventType.syncCompleted)
    }
    
    func testParallelSync() {
        
        let expectation = super.expectation(description: "making parallel sync")
        
        let paymentDevice = PaymentDevice()
        let secondConnector = MockPaymentDeviceConnector(paymentDevice: paymentDevice)
        _ = paymentDevice.changeDeviceInterface(secondConnector)
        
        let secondSyncOperation = SyncOperation(paymentDevice: paymentDevice, connector: secondConnector, deviceInfo: DeviceInfo(), user: User(JSONString: "{\"id\":\"1\"}")!, syncFactory: mocksFactory)
        
        commitsFetcher.commits = [commitsFetcher.getCreateCardCommit(id: "1"), commitsFetcher.getAPDUCommit()]
        
        secondConnector.connectDelayTime = 0.1 // second operation should work faster
        secondConnector.apduExecuteDelayTime = 0.01
        connector.connectDelayTime = 0.3
        connector.apduExecuteDelayTime = 0.01
        
        var syncCompleteCounter = 0
        
        syncOperation.start().subscribe(onNext: { (event) in
            if event.event == .syncCompleted {
                XCTAssertEqual(syncCompleteCounter, 1)
                expectation.fulfill()
            }
        }).disposed(by: self.disposeBag)
        
        secondSyncOperation.start().subscribe(onNext: { (event) in
            if event.event == .syncCompleted {
                syncCompleteCounter += 1
            }
        }).disposed(by: self.disposeBag)
        
        super.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSyncWithUnknownCommitType() {
        connector.connectDelayTime = 0.001
        commitsFetcher.commits = [commitsFetcher.getCreateCardCommit(id: "1"), commitsFetcher.getUnknownCommitType()]
        guard let events = try? syncOperation.start().toBlocking(timeout: 2).toArray() else {
            XCTAssert(false, "Timeouted.")
            return
        }
        events.forEach{ print("Event: \($0.event.eventDescription()), data: \($0.data)") }
        XCTAssertTrue(events.contains { $0.event == SyncEventType.cardAdded })
        XCTAssertEqual(events.last?.event, SyncEventType.syncCompleted)
    }
}

