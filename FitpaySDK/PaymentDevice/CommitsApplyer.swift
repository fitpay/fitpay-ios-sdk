
internal class CommitsApplyer {
    private var commits : [Commit]!
    private let semaphore = dispatch_semaphore_create(0)
    private var thread : NSThread?
    private var applyerCompletionHandler : ApplyerCompletionHandler!
    private var totalApduCommands = 0
    private var appliedApduCommands = 0
    private let maxCommitsRetries = 0
    private let maxAPDUCommandsRetries = 2
    
    internal var isRunning : Bool {
        guard let thread = self.thread else {
            return false
        }
        
        return thread.executing
    }
    
    internal typealias ApplyerCompletionHandler = (error: ErrorType?)->Void
    
    internal func apply(commits:[Commit], completion: ApplyerCompletionHandler) -> Bool {
        if isRunning {
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
        self.thread = NSThread(target: self, selector:#selector(CommitsApplyer.processCommits), object: nil)
        self.thread?.start()
        
        return true
    }
    
    @objc private func processCommits() {
        var commitsApplied = 0
        for commit in commits {
            var errorItr : ErrorType? = nil
            
            // retry if error occurred
            for _ in 0 ..< maxCommitsRetries+1 {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                {
                    self.processCommit(commit)
                    {
                        (error) -> Void in
                        errorItr = error
                        dispatch_semaphore_signal(self.semaphore)
                    }
                })
                
                dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
                
                // if there is no error than leave retry cycle
                if errorItr == nil {
                    break
                }
            }
            
            if let error = errorItr {
                dispatch_async(dispatch_get_main_queue(),
                {
                    self.applyerCompletionHandler(error: error)
                })
                return
            }
            
            commitsApplied += 1
            
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.SYNC_PROGRESS, params: ["applied":commitsApplied, "total":commits.count])
        }
        
        dispatch_async(dispatch_get_main_queue(),
        {
            self.applyerCompletionHandler(error: nil)
        })
    }
    
    private typealias CommitCompletion = (error: ErrorType?)->Void
    
    private func processCommit(commit: Commit, completion: CommitCompletion) {
        guard let commitType = commit.commitType else {
            completion(error: NSError.unhandledError(SyncManager.self))
            return
        }
        
        let commitCompletion = { (error: ErrorType?) -> Void in
            if error == nil {
                SyncManager.sharedInstance.commitCompleted(commit.commit!)
            }
            
            completion(error: error)
        }
        
        switch (commitType) {
        case CommitType.APDU_PACKAGE:
            processAPDUCommit(commit, completion: commitCompletion)
        default:
            processNonAPDUCommit(commit, completion: commitCompletion)
        }
    }
    
    private func processAPDUCommit(commit: Commit, completion: CommitCompletion) {
        guard let apduPackage = commit.payload?.apduPackage else {
            completion(error: NSError.unhandledError(SyncManager.self))
            return
        }
        
        let applyingStartDate = NSDate().timeIntervalSince1970
        
        if apduPackage.isExpired {
            apduPackage.state = APDUPackageResponseState.EXPIRED
            
            // is this error?
            commit.confirmAPDU(
            {
                (error) -> Void in
                completion(error: error)
            })
            
            return
        }
        
        self.applyAPDUPackage(apduPackage, apduCommandIndex: 0, retryCount: 0)
        {
            (error) -> Void in

            let currentTimestamp = NSDate().timeIntervalSince1970

            apduPackage.executedDuration = Int(currentTimestamp - applyingStartDate)
            apduPackage.executedEpoch = CLong(currentTimestamp)
            
            if (error != nil && error as? NSError != nil && (error as! NSError).code == PaymentDevice.ErrorCode.APDUErrorResponse.rawValue) {
                apduPackage.state = APDUPackageResponseState.FAILED
            } else if error != nil {
                apduPackage.state = APDUPackageResponseState.ERROR
            } else {
                apduPackage.state = APDUPackageResponseState.PROCESSED
            }
            
            //TODO: uncomment this when apdu will be implemented on backend
//            commit.confirmAPDU(
//            {
//                (confirmError) -> Void in
//                completion(error: error ?? confirmError)
//            })
            completion(error: error)
        }
    }
    
    private func processNonAPDUCommit(commit: Commit, completion: CommitCompletion) {
        guard let _ = commit.commitType else {
            return
        }
        
        SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.COMMIT_PROCESSED, params: ["commit":commit])

        switch commit.commitType! {
        case .CREDITCARD_CREATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.CARD_ADDED, params: ["commit":commit])
            break;
        case .CREDITCARD_DELETED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.CARD_DELETED, params: ["commit":commit])
            break;
        case .CREDITCARD_ACTIVATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.CARD_ACTIVATED, params: ["commit":commit])
            break;
        case .CREDITCARD_DEACTIVATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.CARD_DEACTIVATED, params: ["commit":commit])
            break;
        case .CREDITCARD_REACTIVATED:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.CARD_REACTIVATED, params: ["commit":commit])
            break;
        case .SET_DEFAULT_CREDITCARD:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.SET_DEFAULT_CARD, params: ["commit":commit])
            break;
        case .RESET_DEFAULT_CREDITCARD:
            SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.RESET_DEFAULT_CARD, params: ["commit":commit])
            break;
        default:
            break;
        }
        
        completion(error: nil)
    }
    
    private func applyAPDUPackage(apduPackage: ApduPackage, apduCommandIndex: Int, retryCount: Int, completion: (error:ErrorType?)->Void) {
        let isFinished = apduPackage.apduCommands?.count <= apduCommandIndex
        
        if isFinished {
            completion(error: nil)
            return
        }
        
        var apdu = apduPackage.apduCommands![apduCommandIndex]
        SyncManager.sharedInstance.paymentDevice!.executeAPDUCommand(&apdu, completion:
        {
            [unowned self] (apduPack, error) -> Void in

            if let error = error {
                if retryCount >= self.maxAPDUCommandsRetries {
                    completion(error: error)
                } else {
                    self.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex, retryCount: retryCount + 1, completion: completion)
                }
            } else {
                self.appliedApduCommands += 1
                
                SyncManager.sharedInstance.callCompletionForSyncEvent(SyncEventType.APDU_COMMANDS_PROGRESS, params: ["applied":self.appliedApduCommands, "total":self.totalApduCommands])
                
                self.applyAPDUPackage(apduPackage, apduCommandIndex: apduCommandIndex + 1, retryCount: 0, completion: completion)
            }
        })
    }
}