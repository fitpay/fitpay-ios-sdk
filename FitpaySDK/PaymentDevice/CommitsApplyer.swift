import RxSwift

internal class CommitsApplyer {

    init(paymentDevice: PaymentDevice,
         deviceInfo: DeviceInfo,
         eventsPublisher: PublishSubject<SyncEvent>,
         syncFactory: SyncFactory,
         syncStorage: SyncStorage) {
        self.paymentDevice           = paymentDevice
        self.eventsPublisher         = eventsPublisher
        self.syncStorage             = syncStorage
        self.deviceInfo              = deviceInfo
        self.apduConfirmOperation    = syncFactory.apduConfirmOperation()
        self.nonApduConfirmOperation = syncFactory.nonApduConfirmOperation()
    }
    
    internal var isRunning: Bool {
        guard let thread = self.thread else {
            return false
        }

        return thread.isExecuting
    }

    internal typealias ApplyerCompletionHandler = (_ error: Error?) -> Void

    internal func apply(_ commits: [Commit], completion: @escaping ApplyerCompletionHandler) -> Bool {
        if isRunning {
            log.warning("SYNC_DATA: Cannot apply commints, applying already in progress.")
            return false
        }

        self.commits = commits

        totalApduCommands = 0
        appliedApduCommands = 0
        for commit in commits {
            if commit.commitType == CommitType.APDU_PACKAGE {
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
    
    internal var apduConfirmOperation: APDUConfirmOperationProtocol
    internal var nonApduConfirmOperation: NonAPDUConfirmOperationProtocol
    
    // private
    fileprivate var commits: [Commit]!
    fileprivate let semaphore = DispatchSemaphore(value: 0)
    fileprivate var thread: Thread?
    fileprivate var applyerCompletionHandler: ApplyerCompletionHandler!
    fileprivate var totalApduCommands = 0
    fileprivate var appliedApduCommands = 0
    fileprivate let maxCommitsRetries = 0
    fileprivate let maxAPDUCommandsRetries = 0
    fileprivate let paymentDevice: PaymentDevice
    fileprivate var syncStorage: SyncStorage
    fileprivate var deviceInfo: DeviceInfo
    internal var commitStatistics = [CommitStatistic]()
    
    // rx
    fileprivate let eventsPublisher: PublishSubject<SyncEvent>
    fileprivate var disposeBag = DisposeBag()

    @objc fileprivate func processCommits() {
        var commitsApplied = 0
        commitStatistics = []
        for commit in commits {
            var errorItr: Error? = nil

            // retry if error occurred
            for _ in 0 ..< maxCommitsRetries + 1 {
                DispatchQueue.global().async(execute: {
                    self.processCommit(commit) { (error) -> Void in
                        errorItr = error
                        self.semaphore.signal()
                    }
                })

                let _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                self.saveCommitStatistic(commit:commit, error: errorItr)
                
                // if there is no error than leave retry cycle
                if errorItr == nil {
                    break
                }
            }

            if let error = errorItr {
                DispatchQueue.main.async(execute: {
                    self.applyerCompletionHandler(error)
                })
                return
            }

            commitsApplied += 1
            
            eventsPublisher.onNext(SyncEvent(event: .syncProgress, data: ["applied": commitsApplied, "total": commits.count]))
        }

        DispatchQueue.main.async(execute: {
            self.applyerCompletionHandler(nil)
        })
    }

    fileprivate typealias CommitCompletion = (_ error: Error?) -> Void

    fileprivate func processCommit(_ commit: Commit, completion: @escaping CommitCompletion) {
        guard let commitType = commit.commitType else {
            log.error("SYNC_DATA: trying to process commit without commitType.")
            completion(NSError.unhandledError(CommitsApplyer.self))
            return
        }

        let commitCompletion = { (error: Error?) -> Void in
            if let deviceId = self.deviceInfo.deviceIdentifier, let commit = commit.commit {
                self.saveLastCommitId(deviceIdentifier:  deviceId, commitId: commit)
            } else {
                log.error("SYNC_DATA: Can't get deviceId or commitId.")
            }

            completion(error)
        }
        
        switch (commitType) {
        case CommitType.APDU_PACKAGE:
            log.verbose("SYNC_DATA: processing APDU commit.")
            processAPDUCommit(commit, completion: commitCompletion)
        default:
            log.verbose("SYNC_DATA: processing non-APDU commit.")
            processNonAPDUCommit(commit, completion: commitCompletion)
        }
    }

    fileprivate func saveLastCommitId(deviceIdentifier: String?, commitId: String?) {
        if let deviceId = deviceIdentifier, let storedCommitId = commitId {
            if let setDeviceLastCommitId = self.paymentDevice.deviceInterface.setDeviceLastCommitId, let _ = self.paymentDevice.deviceInterface.getDeviceLastCommitId {
                setDeviceLastCommitId(storedCommitId)
            } else {
                self.syncStorage.setLastCommitId(deviceId, commitId: storedCommitId)
            }
        } else {
            log.error("SYNC_DATA: Can't get deviceId or commitId.")
        }
    }
    
    fileprivate func processAPDUCommit(_ commit: Commit, completion: @escaping CommitCompletion) {
        log.debug("SYNC_DATA: Processing APDU commit: \(commit.commit ?? "").")
        guard let apduPackage = commit.payload?.apduPackage else {
            log.error("SYNC_DATA: trying to process apdu commit without apdu package.")
            completion(NSError.unhandledError(CommitsApplyer.self))
            return
        }

        let applyingStartDate = Date().timeIntervalSince1970


        if apduPackage.isExpired {
            log.warning("SYNC_DATA: package ID(\(commit.commit ?? "nil")) expired. ")
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

            self?.applyAPDUPackage(apduPackage, apduCommandIndex: 0, retryCount: 0) { (state, error) in
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

                var realError: NSError? = nil
                if apduPackage.state == .notProcessed || apduPackage.state == .error {
                    realError = error as NSError?
                }

                self?.eventsPublisher.onNext(SyncEvent(event: .apduPackageComplete, data: ["package": apduPackage, "error": realError ?? "nil"]))

                self?.paymentDevice.apduPackageProcessingFinished(apduPackage, completion: { (error) in
                    guard error == nil else {
                        completion(error)
                        return
                    }

                    log.debug("SYNC_DATA: Processed APDU commit (\(commit.commit ?? "nil")) with state: \(apduPackage.state?.rawValue ?? "nil") and error: \(String(describing: realError)).")

                    if apduPackage.state == .notProcessed {
                        completion(realError)
                    } else {
                        self?.apduConfirmOperation.startWith(commit: commit).subscribe() { (e) in
                            switch e {
                            case .completed:
                                completion(realError)
                                break
                            case .error(let error):
                                log.debug("SYNC_DATA: Apdu package confirmed with error: \(error).")
                                completion(error)
                                break
                            case .next:
                                break
                            }
                        }.disposed(by: self?.disposeBag ?? DisposeBag())
                    }
                })
            }
        }
    }

    fileprivate func processNonAPDUCommit(_ commit: Commit, completion: @escaping CommitCompletion) {
        guard let commitType = commit.commitType else {
            return
        }
        
        let applyingStartDate = Date().timeIntervalSince1970
        
        self.paymentDevice.processNonAPDUCommit(commit: commit) { [weak self] (state, error) in
            let currentTimestamp = Date().timeIntervalSince1970
            commit.executedDuration = Int((currentTimestamp - applyingStartDate)*1000)

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
                    
                    var syncEvent: SyncEvent? = nil
                    switch commitType {
                    case .CREDITCARD_CREATED:
                        syncEvent = SyncEvent(event: .cardAdded, data: eventData)
                        break
                    case .CREDITCARD_DELETED:
                        syncEvent = SyncEvent(event: .cardDeleted, data: eventData)
                        break
                    case .CREDITCARD_ACTIVATED:
                        syncEvent = SyncEvent(event: .cardActivated, data: eventData)
                        break
                    case .CREDITCARD_DEACTIVATED:
                        syncEvent = SyncEvent(event: .cardDeactivated, data: eventData)
                        break
                    case .CREDITCARD_REACTIVATED:
                        syncEvent = SyncEvent(event: .cardReactivated, data: eventData)
                        break
                    case .SET_DEFAULT_CREDITCARD:
                        syncEvent = SyncEvent(event: .setDefaultCard, data: eventData)
                        break
                    case .RESET_DEFAULT_CREDITCARD:
                        syncEvent = SyncEvent(event: .resetDefaultCard, data: eventData)
                        break
                    case .APDU_PACKAGE:
                        log.warning("Processed APDU package inside nonapdu handler.")
                        break
                    case .CREDITCARD_PROVISION_FAILED:
                        syncEvent = SyncEvent(event: .cardProvisionFailed, data: eventData)
                        break
                    case .CREDITCARD_METADATA_UPDATED:
                        syncEvent = SyncEvent(event: .cardMetadataUpdated, data: eventData)
                        break
                    case .UNKNOWN:
                        log.warning("Received new (unknown) commit type - \(commit.commitTypeString ?? "").")
                        break
                    }
                    
                    if let syncEvent = syncEvent {
                        self?.eventsPublisher.onNext(syncEvent)
                    }
                    
                    completion(nil)

                    break
                case .error(let error):
                    log.debug("SYNC_DATA: non APDU commit confirmed with error: \(error).")
                    completion(error)
                    break
                case .next:
                    break
                }
                
            }.disposed(by: self?.disposeBag ?? DisposeBag())
        }
    }

    fileprivate func applyAPDUPackage(_ apduPackage: ApduPackage,
                                      apduCommandIndex: Int,
                                      retryCount: Int,
                                      completion: @escaping (_ state: APDUPackageResponseState?, _ error: Error?) -> Void) {
        let isFinished = (apduPackage.apduCommands?.count)! <= apduCommandIndex

        guard !isFinished else {
            completion(apduPackage.state, nil)
            return
        }

        var mutableApduPackage = apduPackage.apduCommands![apduCommandIndex]
        self.paymentDevice.executeAPDUCommand(mutableApduPackage) { [weak self] (apduPack, state, error) in
            apduPackage.state = state

            if let apduPack = apduPack {
                mutableApduPackage = apduPack
            }

            if let error = error {
                if retryCount >= self?.maxAPDUCommandsRetries ?? 1 {
                    completion(state, error)
                } else {
                    self?.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex, retryCount: retryCount + 1, completion: completion)
                }
            } else {
                self?.appliedApduCommands += 1
                log.info("SYNC_DATA: PROCESSED \(self?.appliedApduCommands ?? 0)/\(self?.totalApduCommands ?? 0) COMMANDS")

                self?.eventsPublisher.onNext(SyncEvent(event: .apduCommandsProgress, data: ["applied": self?.appliedApduCommands ?? 0, "total": self?.totalApduCommands ?? 0]))

                self?.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex + 1, retryCount: 0, completion: completion)
            }
        }
    }
    
    fileprivate func saveCommitStatistic(commit:Commit, error: Error?) {
        guard let commitType = commit.commitType else {
            let statistic = CommitStatistic(commitId:commit.commit, total:0, average:0, errorDesc:error?.localizedDescription)
            self.commitStatistics.append(statistic)
            return
        }
        
        switch (commitType) {
        case CommitType.APDU_PACKAGE:
            let total = commit.payload?.apduPackage?.executedDuration ?? 0
            let commandsCount = commit.payload?.apduPackage?.apduCommands?.count ?? 1
            
            let statistic = CommitStatistic(commitId: commit.commit,
                                              total: total,
                                              average: total/commandsCount,
                                              errorDesc: error?.localizedDescription)
            self.commitStatistics.append(statistic)
        default:
            let statistic = CommitStatistic(commitId: commit.commit,
                                              total: commit.executedDuration,
                                              average: commit.executedDuration,
                                              errorDesc: error?.localizedDescription)
            self.commitStatistics.append(statistic)
        }
    }
}
