import Foundation
import RxSwift

class SyncOperation {

    var fetchCommitsOperation: FetchCommitsOperationProtocol // Dependency Injection
    var commitsApplyer: CommitsApplyer
    
    private var paymentDevice: PaymentDevice
    private var connector: PaymentDeviceConnectable
    private var deviceInfo: Device
    private var user: User
    private var connectOperation: ConnectDeviceOperationProtocol
    private var eventsAdapter: SyncOperationStateToSyncEventAdapter
    private var syncStorage: SyncStorage
    private var syncRequest: SyncRequest?
    
    private var syncEventsPublisher: PublishSubject<SyncEvent>
    private var state: Variable<SyncOperationState>
    private var disposeBag = DisposeBag()
    
    private var isSyncing = false
    
    // MARK: - Lifecycle
    
    init(paymentDevice: PaymentDevice, connector: PaymentDeviceConnectable, deviceInfo: Device, user: User, syncFactory: SyncFactory, syncStorage: SyncStorage = SyncStorage.sharedInstance, syncRequest: SyncRequest) {
        
        self.paymentDevice = paymentDevice
        self.connector     = connector
        self.deviceInfo    = deviceInfo
        self.user          = user
        
        self.syncEventsPublisher   = PublishSubject<SyncEvent>()
        self.commitsApplyer        = CommitsApplyer(paymentDevice: self.paymentDevice,
                                                    deviceInfo: self.deviceInfo,
                                                    eventsPublisher: self.syncEventsPublisher,
                                                    syncFactory: syncFactory,
                                                    syncStorage: syncStorage)
        self.state                 = Variable(.waiting)
        self.connectOperation      = syncFactory.connectDeviceOperationWith(paymentDevice: paymentDevice)
        self.eventsAdapter         = SyncOperationStateToSyncEventAdapter(stateObservable: self.state.asObservable(),
                                                                          publisher: self.syncEventsPublisher)
        
        self.fetchCommitsOperation = syncFactory.commitsFetcherOperationWith(deviceInfo: deviceInfo, connector: connector)
        
        self.syncStorage = syncStorage
        self.syncRequest = syncRequest
    }
    
    // MARK: - Internal Functions
    
    func start() -> Observable<SyncEvent> {
        self.state.asObservable().subscribe(onNext: { [weak self] (state) in
            switch state {
            case .waiting, .connected, .connecting, .commitsReceived:
                break
            case .started:
                self?.isSyncing = true
            case .completed:
                self?.isSyncing = false
            }
        }).disposed(by: disposeBag)
        
        guard self.isSyncing == false else {
            state.value = .completed(SyncOperationError.alreadySyncing)
            return eventsAdapter.startAdapting()
        }
        
        // we need to update notification token first, because during sync we can receive push notifications
        self.deviceInfo.updateNotificationTokenIfNeeded { [weak self] (_, _) in
            self?.startSync()
        }
        
        return eventsAdapter.startAdapting()
    }
    
    // MARK: - Private Functions
    
    private func startSync() {
        self.connectOperation.start().subscribe { [weak self] (event) in
            switch event {
            case .error(let error):
                self?.state.value = .completed(error)
            case .next(let state):
                switch state {
                case .connected:
                    self?.state.value = .connected
                    self?.sync()
                case .connecting:
                    self?.state.value = .connecting
                case .disconnected:
                    if self?.isSyncing == true {
                        self?.state.value = .completed(SyncOperationError.paymentDeviceDisconnected)
                    }
                }
            case .completed:
                break
            }
            }.disposed(by: self.disposeBag)
    }
    
    private func sync() {
        self.syncRequest?.notification?.sendAckSync()
        self.fetchCommitsOperation.startWith(limit: 20, andOffset: 0).subscribe { [weak self] (e) in
            switch e {
            case .error(let error):
                log.error("SYNC_DATA: Can't fetch commits. Error: \(error)")
                self?.sendCommitsMetric()
                self?.state.value = .completed(SyncManager.ErrorCode.cantFetchCommits)
            case .next(let commits):
                self?.state.value = .commitsReceived(commits: commits)
                
                let applyerStarted = self?.commitsApplyer.apply(commits) { (error) in
                    
                    if let error = error {
                        log.error("SYNC_DATA: Commit applier returned a failure: \(error)")
                        self?.state.value = .completed(error)
                        return
                    }
                    
                    log.verbose("SYNC_DATA: Commit applier returned without errors.")
                    
                    self?.state.value = .completed(nil)
                }
                
                if applyerStarted ?? false == false {
                    self?.state.value = .completed(NSError.error(code: SyncManager.ErrorCode.commitsApplyerIsBusy, domain: SyncOperation.self))
                }
            case .completed:
                self?.sendCommitsMetric()
            }
            }.disposed(by: disposeBag)
        
    }
    
    private func sendCommitsMetric() {
        guard let notification = syncRequest?.notification else { return }
        
        let currentTimestamp = Date().timeIntervalSince1970
        
        let metric = CommitMetrics()
        metric.commitStatistics = commitsApplyer.commitStatistics
        metric.deviceId = deviceInfo.deviceIdentifier
        metric.userId = user.id
        metric.initiator = syncRequest?.syncInitiator
        metric.notification = syncRequest?.notification
        metric.totalProcessingTimeMs = Int((currentTimestamp - (syncRequest?.syncStartTime?.timeIntervalSince1970)!)*1000)
        
        notification.sendCompleteSync(commitMetrics: metric)
    }

}
