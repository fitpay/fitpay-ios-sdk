import RxSwift

class CommitsApplyer {
    
    var apduConfirmOperation: APDUConfirmOperationProtocol
    var nonApduConfirmOperation: NonAPDUConfirmOperationProtocol
    
    var commitStatistics = [CommitStatistic]()
    
    private var commits: [Commit]!
    private let semaphore = DispatchSemaphore(value: 0)
    private var thread: Thread?
    private var applyerCompletionHandler: CompletionHandler!
    private var totalApduCommands = 0
    private var appliedApduCommands = 0
    private let maxCommitsRetries = 0
    private let paymentDevice: PaymentDevice
    private var syncStorage: SyncStorage
    private var deviceInfo: Device

    // rx
    private let eventsPublisher: PublishSubject<SyncEvent>
    private var disposeBag = DisposeBag()
    
    var isRunning: Bool {        
        return thread?.isExecuting ?? false
    }
    
    typealias CompletionHandler = (_ error: Error?) -> Void

    // MARK: - Lifecycle
    
    init(paymentDevice: PaymentDevice, deviceInfo: Device, eventsPublisher: PublishSubject<SyncEvent>, syncFactory: SyncFactory, syncStorage: SyncStorage) {
        self.paymentDevice           = paymentDevice
        self.eventsPublisher         = eventsPublisher
        self.syncStorage             = syncStorage
        self.deviceInfo              = deviceInfo
        self.apduConfirmOperation    = syncFactory.apduConfirmOperation()
        self.nonApduConfirmOperation = syncFactory.nonApduConfirmOperation()
    }
    
    // MARK: - Internal Functions
    
    func apply(_ commits: [Commit], completion: @escaping CompletionHandler) -> Bool {
        if isRunning {
            log.warning("SYNC_DATA: Cannot apply commints, applying already in progress.")
            return false
        }
        
        self.commits = commits
        
        totalApduCommands = 0
        appliedApduCommands = 0
        for commit in commits {
            if commit.commitType == CommitType.apduPackage {
                if let apduCommandsCount = commit.payload?.apduPackage?.apduCommands?.count {
                    totalApduCommands += apduCommandsCount
                }
            }
        }
        
        self.applyerCompletionHandler = completion
        self.thread = Thread(target: self, selector: #selector(CommitsApplyer.processCommits), object: nil)
        self.thread?.qualityOfService = .utility
        self.thread?.start()
        
        return true
    }
    
    // MARK: - Private Functions
    
    @objc private func processCommits() {
        var commitsApplied = 0
        commitStatistics = []
        for commit in commits {
            var errorItr: Error?
            
            // retry if error occurred
            for _ in 0 ..< maxCommitsRetries + 1 {
                DispatchQueue.global().async {
                    self.processCommit(commit) { (error) -> Void in
                        errorItr = error
                        self.semaphore.signal()
                    }
                }
                
                _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                self.saveCommitStatistic(commit: commit, error: errorItr)
                
                // if there is no error than leave retry cycle
                if errorItr == nil {
                    break
                }
            }
            
            if let error = errorItr {
                DispatchQueue.main.async {
                    self.applyerCompletionHandler(error)
                }
                return
            }
            
            commitsApplied += 1
            
            eventsPublisher.onNext(SyncEvent(event: .syncProgress, data: ["applied": commitsApplied, "total": commits.count]))
        }
        
        DispatchQueue.main.async {
            self.applyerCompletionHandler(nil)
        }
    }
    
    private func processCommit(_ commit: Commit, completion: @escaping CompletionHandler) {
        guard let commitType = commit.commitType else {
            log.error("SYNC_DATA: trying to process commit without commitType.")
            completion(NSError.unhandledError(CommitsApplyer.self))
            return
        }
        
        let commitCompletion = { (error: Error?) -> Void in
            if let deviceId = self.deviceInfo.deviceIdentifier, let commit = commit.commitId {
                self.saveLastCommitId(deviceIdentifier: deviceId, commitId: commit)
            } else {
                log.error("SYNC_DATA: Can't get deviceId or commitId.")
            }
            
            completion(error)
        }
        
        switch (commitType) {
        case CommitType.apduPackage:
            log.verbose("SYNC_DATA: processing APDU commit.")
            processAPDUCommit(commit, completion: commitCompletion)
        default:
            log.verbose("SYNC_DATA: processing non-APDU commit.")
            processNonAPDUCommit(commit, completion: commitCompletion)
        }
    }
    
    private func saveLastCommitId(deviceIdentifier: String?, commitId: String?) {
        if let deviceId = deviceIdentifier, let storedCommitId = commitId {
            if let setDeviceLastCommitId = self.paymentDevice.deviceInterface.setDeviceLastCommitId, self.paymentDevice.deviceInterface.getDeviceLastCommitId != nil {
                setDeviceLastCommitId(storedCommitId)
            } else {
                self.syncStorage.setLastCommitId(deviceId, commitId: storedCommitId)
            }
        } else {
            log.error("SYNC_DATA: Can't get deviceId or commitId.")
        }
    }
    
    private func processAPDUCommit(_ commit: Commit, completion: @escaping CompletionHandler) {
        log.debug("SYNC_DATA: Processing APDU commit: \(commit.commitId ?? "").")
        guard let apduPackage = commit.payload?.apduPackage else {
            log.error("SYNC_DATA: trying to process apdu commit without apdu package.")
            completion(NSError.unhandledError(CommitsApplyer.self))
            return
        }
        
        let applyingStartDate = Date().timeIntervalSince1970
        
        if apduPackage.isExpired {
            log.warning("SYNC_DATA: package ID(\(commit.commitId ?? "nil")) expired. ")
            apduPackage.state = APDUPackageResponseState.expired
            apduPackage.executedDuration = 0
            apduPackage.executedEpoch = Date().timeIntervalSince1970
            
            // is this error?
            commit.confirmAPDU { (error) -> Void in
                completion(error)
            }
            
            return
        }
        
        self.paymentDevice.apduPackageProcessingStarted(apduPackage) { [weak self] (error) in
            guard error == nil else {
                completion(error)
                return
            }
            
            if self?.paymentDevice.executeAPDUPackageAllowed == true {
                self?.paymentDevice.executeAPDUPackage(apduPackage) { (error) in
                    self?.packageProcessingFinished(commit: commit, apduPackage: apduPackage, state: nil, error: error, applyingStartDate: applyingStartDate) { commitError in
                        completion(commitError)
                    }
                }
            } else {
                self?.applyAPDUPackage(apduPackage, apduCommandIndex: 0, retryCount: 0) { (state, error) in
                    self?.packageProcessingFinished(commit: commit, apduPackage: apduPackage, state: state, error: error, applyingStartDate: applyingStartDate) { commitError in
                        completion(commitError)
                    }
                }
            }
        }
    }
    
    private func packageProcessingFinished(commit: Commit, apduPackage: ApduPackage, state: APDUPackageResponseState?, error: Error?, applyingStartDate: TimeInterval, completion: @escaping CompletionHandler) {
        let currentTimestamp = Date().timeIntervalSince1970
        
        apduPackage.executedDuration = Int((currentTimestamp - applyingStartDate)*1000)
        apduPackage.executedEpoch = TimeInterval(currentTimestamp)
        
        if state == nil {
            if error != nil && error as NSError? != nil && (error! as NSError).code == PaymentDevice.ErrorCode.apduErrorResponse.rawValue {
                log.debug("SYNC_DATA: Got a failed APDU response.")
                apduPackage.state = APDUPackageResponseState.failed
            } else if error != nil {
                // This will catch (error as! NSError).code == PaymentDevice.ErrorCode.apduSendingTimeout.rawValue
                log.debug("SYNC_DATA: Got failure on apdu.")
                apduPackage.state = APDUPackageResponseState.error
            } else {
                apduPackage.state = APDUPackageResponseState.processed
            }
        } else {
            apduPackage.state = state
        }
        
        var realError: NSError?
        if apduPackage.state == .notProcessed || apduPackage.state == .error {
            realError = error as NSError?
        }
        
        self.eventsPublisher.onNext(SyncEvent(event: .apduPackageComplete, data: ["package": apduPackage, "error": realError ?? "nil"]))
        
        self.paymentDevice.apduPackageProcessingFinished(apduPackage, completion: { (error) in
            guard error == nil else {
                completion(error)
                return
            }
            
            log.debug("SYNC_DATA: Processed APDU commit (\(commit.commitId ?? "nil")) with state: \(apduPackage.state?.rawValue ?? "nil") and error: \(String(describing: realError)).")
            
            if apduPackage.state == .notProcessed {
                completion(realError)
            } else {
                self.apduConfirmOperation.startWith(commit: commit).subscribe { (e) in
                    switch e {
                    case .completed:
                        completion(realError)
                    case .error(let error):
                        log.debug("SYNC_DATA: Apdu package confirmed with error: \(error).")
                        completion(error)
                    case .next:
                        break
                    }
                    }.disposed(by: self.disposeBag)
            }
        })
    }
    
    private func processNonAPDUCommit(_ commit: Commit, completion: @escaping CompletionHandler) {
        guard let commitType = commit.commitType else { return }
        
        let applyingStartDate = Date().timeIntervalSince1970
        
        self.paymentDevice.processNonAPDUCommit(commit: commit) { [weak self] (state, error) in
            let currentTimestamp = Date().timeIntervalSince1970
            commit.executedDuration = Int((currentTimestamp - applyingStartDate) * 1000)
            
            self?.nonApduConfirmOperation.startWith(commit: commit, result: state ?? .failed).subscribe { (e) in
                switch e {
                case .completed:
                    guard state != .failed else {
                        log.error("SYNC_DATA: received failed state for processing non apdu commit.")
                        completion(error ?? NSError.unhandledError(CommitsApplyer.self))
                        return
                    }
                    
                    let eventData = ["commit": commit]
                    self?.eventsPublisher.onNext(SyncEvent(event: .commitProcessed, data: eventData))
                    
                    var syncEvent: SyncEvent?
                    switch commitType {
                    case .creditCardCreated:
                        syncEvent = SyncEvent(event: .cardAdded, data: eventData)
                    case .creditCardDeleted:
                        syncEvent = SyncEvent(event: .cardDeleted, data: eventData)
                    case .creditCardActivated:
                        syncEvent = SyncEvent(event: .cardActivated, data: eventData)
                    case .creditCardDeactivated:
                        syncEvent = SyncEvent(event: .cardDeactivated, data: eventData)
                    case .creditCardReactivated:
                        syncEvent = SyncEvent(event: .cardReactivated, data: eventData)
                    case .setDefaultCreditCard:
                        syncEvent = SyncEvent(event: .setDefaultCard, data: eventData)
                    case .resetDefaultCreditCard:
                        syncEvent = SyncEvent(event: .resetDefaultCard, data: eventData)
                    case .apduPackage:
                        log.warning("SYNC_DATA: Processed APDU package inside nonapdu handler.")
                    case .creditCardProvisionFailed:
                        syncEvent = SyncEvent(event: .cardProvisionFailed, data: eventData)
                    case .creditCardProvisionSuccess:
                        syncEvent = SyncEvent(event: .cardProvisionSuccess, data: eventData)
                    case .creditCardMetaDataUpdated:
                        syncEvent = SyncEvent(event: .cardMetadataUpdated, data: eventData)
                    case .unknown:
                        log.warning("SYNC_DATA: Received new (unknown) commit type - \(commit.commitTypeString ?? "").")
                    }
                    
                    if let syncEvent = syncEvent {
                        self?.eventsPublisher.onNext(syncEvent)
                    }
                    
                    completion(nil)
                    
                case .error(let error):
                    log.debug("SYNC_DATA: non APDU commit confirmed with error: \(error).")
                    completion(error)
                case .next:
                    break
                }
                
                }.disposed(by: self?.disposeBag ?? DisposeBag())
        }
    }
    
    private func applyAPDUPackage(_ apduPackage: ApduPackage, apduCommandIndex: Int, retryCount: Int, completion: @escaping (_ state: APDUPackageResponseState?, _ error: Error?) -> Void) {
        let isFinished = (apduPackage.apduCommands?.count)! <= apduCommandIndex
        
        guard !isFinished else {
            completion(apduPackage.state, nil)
            return
        }
        
        var mutableApduCommand = apduPackage.apduCommands![apduCommandIndex]
        
        self.paymentDevice.executeAPDUCommand(mutableApduCommand) { [weak self] (apduCommand, state, error) in
            apduPackage.state = state
            
            if let apduCommand = apduCommand {
                mutableApduCommand = apduCommand
            }
            
            guard error == nil else {
                completion(state, error)
                return
            }
            
            self?.appliedApduCommands += 1
            log.info("SYNC_DATA: PROCESSED \(self?.appliedApduCommands ?? 0)/\(self?.totalApduCommands ?? 0) COMMANDS")
            
            self?.eventsPublisher.onNext(SyncEvent(event: .apduCommandsProgress, data: ["applied": self?.appliedApduCommands ?? 0, "total": self?.totalApduCommands ?? 0]))
            
            //process next
            self?.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex + 1, retryCount: 0, completion: completion)
        }
    }
    
    private func saveCommitStatistic(commit: Commit, error: Error?) {
        guard let commitType = commit.commitType else {
            let statistic = CommitStatistic(commitId: commit.commitId, total: 0, average: 0, errorDesc: error?.localizedDescription)
            self.commitStatistics.append(statistic)
            return
        }
        
        switch (commitType) {
        case CommitType.apduPackage:
            let total = commit.payload?.apduPackage?.executedDuration ?? 0
            let commandsCount = commit.payload?.apduPackage?.apduCommands?.count ?? 1
            
            let statistic = CommitStatistic(commitId: commit.commitId,
                                            total: total,
                                            average: total/commandsCount,
                                            errorDesc: error?.localizedDescription)
            self.commitStatistics.append(statistic)
        default:
            let statistic = CommitStatistic(commitId: commit.commitId,
                                            total: commit.executedDuration,
                                            average: commit.executedDuration,
                                            errorDesc: error?.localizedDescription)
            self.commitStatistics.append(statistic)
        }
    }

}
