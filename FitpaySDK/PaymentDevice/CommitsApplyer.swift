
internal class CommitsApplyer {
    fileprivate var commits : [Commit]!
    fileprivate let semaphore = DispatchSemaphore(value: 0)
    fileprivate var thread : Thread?
    fileprivate var applyerCompletionHandler : ApplyerCompletionHandler!
    fileprivate var totalApduCommands = 0
    fileprivate var appliedApduCommands = 0
    fileprivate let maxCommitsRetries = 0
    fileprivate let maxAPDUCommandsRetries = 0
    
    internal var isRunning : Bool {
        guard let thread = self.thread else {
            return false
        }
        
        return thread.isExecuting
    }
    
    internal typealias ApplyerCompletionHandler = (_ error: Error?)->Void
    
    internal func apply(_ commits:[Commit], completion: @escaping ApplyerCompletionHandler) -> Bool {
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
        self.thread = Thread(target: self, selector:#selector(CommitsApplyer.processCommits), object: nil)
        self.thread?.qualityOfService = .utility
        self.thread?.start()
        
        return true
    }
    
    @objc fileprivate func processCommits() {
        var commitsApplied = 0
        for commit in commits {
            var errorItr : Error? = nil
            
            // retry if error occurred
            for _ in 0 ..< maxCommitsRetries+1 {
                DispatchQueue.global().async(execute: {
                    self.processCommit(commit)
                    {
                        (error) -> Void in
                        errorItr = error
                        self.semaphore.signal()
                    }
                })
                
                let _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                
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
            
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.syncProgress, params: ["applied":commitsApplied, "total":commits.count])
        }
        
        DispatchQueue.main.async(execute: {
            self.applyerCompletionHandler(nil)
        })
    }
    
    fileprivate typealias CommitCompletion = (_ error: Error?)->Void
    
    fileprivate func processCommit(_ commit: Commit, completion: @escaping CommitCompletion) {
        guard let commitType = commit.commitType else {
            completion(NSError.unhandledError(SyncManager.self))
            return
        }
        
        let commitCompletion = { (error: Error?) -> Void in
            if error == nil || (error as? NSError)?.code == PaymentDevice.ErrorCode.apduErrorResponse.rawValue {
                SyncManager.sharedInstance.commitCompleted(commit.commit!)
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
    
    fileprivate func processAPDUCommit(_ commit: Commit, completion: @escaping CommitCompletion) {
        log.debug("SYNC_DATA: Processing APDU commit: \(commit.commit ?? "").")
        guard let apduPackage = commit.payload?.apduPackage else {
            completion(NSError.unhandledError(SyncManager.self))
            return
        }
        
        let applyingStartDate = Date().timeIntervalSince1970
        
        
        if apduPackage.isExpired {
            log.warning("SYNC_DATA: package ID(\(commit.commit ?? "nil")) expired. ")
            apduPackage.state = APDUPackageResponseState.EXPIRED
            
            // is this error?
            commit.confirmAPDU(
            {
                (error) -> Void in
                completion(error)
            })
            
            return
        }
        
        SyncStorage.sharedInstance.lastPackageId += 1
        
        SyncManager.sharedInstance.paymentDevice?.apduPackageProcessingStarted(apduPackage, completion: {
            (error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            self.applyAPDUPackage(apduPackage, apduCommandIndex: 0, retryCount: 0)
            {
                (error) -> Void in
                
                let currentTimestamp = Date().timeIntervalSince1970
                
                apduPackage.executedDuration = Int64(currentTimestamp - applyingStartDate)
                apduPackage.executedEpoch = TimeInterval(currentTimestamp)
                
                if error != nil && error as? NSError != nil && (error as! NSError).code == PaymentDevice.ErrorCode.apduErrorResponse.rawValue {
                    log.debug("SYNC_DATA: Got a failed APDU response.")
                    apduPackage.state = APDUPackageResponseState.FAILED
                } else if error != nil {
                    // This will catch (error as! NSError).code == PaymentDevice.ErrorCode.apduSendingTimeout.rawValue
                    log.debug("SYNC_DATA: Got failure on apdu.")
                    apduPackage.state = APDUPackageResponseState.ERROR
                } else {
                    apduPackage.state = APDUPackageResponseState.PROCESSED
                }
                
                var realError = error
                
                // if we received timeout or apdu with error response than confirm it and move next, do not stop sync process
                if (error as? NSError)?.code == PaymentDevice.ErrorCode.apduErrorResponse.rawValue || (error as? NSError)?.code == PaymentDevice.ErrorCode.apduSendingTimeout.rawValue {
                    realError = nil
                }
                
                SyncManager.sharedInstance.paymentDevice?.apduPackageProcessingFinished(apduPackage, completion: {
                    (error) in
                    
                    guard error == nil else {
                        completion(error)
                        return
                    }
                    
                    log.debug("SYNC_DATA: Processed APDU commit (\(commit.commit ?? "nil")) with state: \(apduPackage.state?.rawValue ?? "nil") and error: \(realError).")
                    commit.confirmAPDU({
                        (confirmError) -> Void in
                        log.debug("SYNC_DATA: Apdu package confirmed with error: \(confirmError).")
                        completion(realError ?? confirmError)
                    })
                })
            }
        })
    }
    
    fileprivate func processNonAPDUCommit(_ commit: Commit, completion: CommitCompletion) {
        guard let _ = commit.commitType else {
            return
        }
        
        SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.commitProcessed, params: ["commit":commit])

        switch commit.commitType! {
        case .CREDITCARD_CREATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.cardAdded, params: ["commit":commit])
            break;
        case .CREDITCARD_DELETED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.cardDeleted, params: ["commit":commit])
            break;
        case .CREDITCARD_ACTIVATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.cardActivated, params: ["commit":commit])
            break;
        case .CREDITCARD_DEACTIVATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.cardDeactivated, params: ["commit":commit])
            break;
        case .CREDITCARD_REACTIVATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.cardReactivated, params: ["commit":commit])
            break;
        case .SET_DEFAULT_CREDITCARD:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.setDefaultCard, params: ["commit":commit])
            break;
        case .RESET_DEFAULT_CREDITCARD:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.resetDefaultCard, params: ["commit":commit])
            break;
        default:
            break;
        }
        
        completion(nil)
    }
    
    fileprivate func applyAPDUPackage(_ apduPackage: ApduPackage, apduCommandIndex: Int, retryCount: Int, completion: @escaping (_ error:Error?)->Void) {
        let isFinished = (apduPackage.apduCommands?.count)! <= apduCommandIndex
        
        if isFinished {
            completion(nil)
            return
        }
        
        var mutableApduPackage = apduPackage.apduCommands![apduCommandIndex]
        SyncManager.sharedInstance.paymentDevice!.executeAPDUCommand(mutableApduPackage, completion:
        {
            [unowned self] (apduPack, error) -> Void in
            
            if let apduPack = apduPack {
                mutableApduPackage = apduPack
            }
            
            if let error = error {
                if retryCount >= self.maxAPDUCommandsRetries {
                    completion(error)
                } else {
                    self.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex, retryCount: retryCount + 1, completion: completion)
                }
            } else {
                self.appliedApduCommands += 1
                
                SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.apduCommandsProgress, params: ["applied":self.appliedApduCommands, "total":self.totalApduCommands])
                
                self.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex + 1, retryCount: 0, completion: completion)
            }
        })
    }
}
