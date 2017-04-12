
import ObjectMapper
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@objc public enum SyncEventType : Int, FitpayEventTypeProtocol {
    case connectingToDevice = 0x1
    case connectingToDeviceFailed
    case connectingToDeviceCompleted
    
    case syncStarted
    case syncFailed
    case syncCompleted
    case syncProgress
    case receivedCardsWithTowApduCommands
    case apduCommandsProgress
    
    case commitsReceived
    case commitProcessed

    case cardAdded
    case cardDeleted
    case cardActivated
    case cardDeactivated
    case cardReactivated
    case setDefaultCard
    case resetDefaultCard
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .connectingToDevice:
            return "Connecting to device"
        case .connectingToDeviceFailed:
            return "Connecting to device failed"
        case .connectingToDeviceCompleted:
            return "Connecting to device completed"
        case .syncStarted:
            return "Sync started"
        case .syncFailed:
            return "Sync failed"
        case .syncCompleted:
            return "Sync completed"
        case .syncProgress:
            return "Sync progress"
        case .receivedCardsWithTowApduCommands:
            return "Received cards with Top of Wallet APDU commands"
        case .apduCommandsProgress:
            return "APDU progress"
        case .commitsReceived:
            return "Commits received"
        case .commitProcessed:
            return "Processed commit"
        case .cardAdded:
            return "New card was added"
        case .cardDeleted:
            return "Card was deleted"
        case .cardActivated:
            return "Card was activated"
        case .cardDeactivated:
            return "Card was deactivated"
        case .cardReactivated:
            return "Card was reactivated"
        case .setDefaultCard:
            return "New default card was manually set"
        case .resetDefaultCard:
            return "New default card was automatically set"
        }
    }
}

open class SyncManager : NSObject {
    open static let sharedInstance = SyncManager()
    open var paymentDevice : PaymentDevice?
    
    open var userId : String? {
        return user?.id
    }
    
    internal let syncStorage : SyncStorage = SyncStorage.sharedInstance
    internal let paymentDeviceConnectionTimeoutInSecs : Int = 60
    
    internal var deviceInfo : DeviceInfo?

    fileprivate let eventsDispatcher = FitpayEventDispatcher()
    fileprivate var user : User?
    
    fileprivate var commitsApplyer = CommitsApplyer()
    
    fileprivate weak var deviceConnectedBinding : FitpayEventBinding?
    fileprivate weak var deviceDisconnectedBinding : FitpayEventBinding?
    
    fileprivate override init() {
        super.init()
    }
    
    public enum ErrorCode : Int, Error, RawIntValue, CustomStringConvertible
    {
        case unknownError                   = 0
        case cantConnectToDevice            = 10001
        case cantApplyAPDUCommand           = 10002
        case cantFetchCommits               = 10003
        case cantFindDeviceWithSerialNumber = 10004
        case syncAlreadyStarted             = 10005
        case commitsApplyerIsBusy           = 10006
        case connectionWithDeviceWasLost    = 10007
        case userIsNill                     = 10008
        
        public var description : String {
            switch self {
            case .unknownError:
                return "Unknown error"
            case .cantConnectToDevice:
                return "Can't connect to payment device."
            case .cantApplyAPDUCommand:
                return "Can't apply APDU command to payment device."
            case .cantFetchCommits:
                return "Can't fetch commits from API."
            case .cantFindDeviceWithSerialNumber:
                return "Can't find device with serial number of connected payment device."
            case .syncAlreadyStarted:
                return "Sync already started."
            case .commitsApplyerIsBusy:
                return "Commits applyer is busy, sync already started?"
            case .connectionWithDeviceWasLost:
                return "Connection with device was lost."
            case .userIsNill:
                return "User is nill"
            }
        }
    }
    
    open fileprivate(set) var isSyncing : Bool = false
    
    /**
     Starts sync process with payment device. 
     If device disconnected, than system tries to connect.
     
     - parameter user:	 user from API to whom device belongs to.
     - parameter device: device which we will sync with. If nil then we will use first one with secureElemendId.
     */
    open func sync(_ user: User, device: DeviceInfo? = nil) -> NSError? {
        log.debug("SYNC_DATA: Starting sync.")
        if self.isSyncing {
            log.warning("SYNC_DATA: Already syncing so can't sync.")
            return NSError.error(code: SyncManager.ErrorCode.syncAlreadyStarted, domain: SyncManager.self)
        }
        
        self.isSyncing = true
        self.user = user
        self.deviceInfo = device
        
        if self.paymentDevice!.isConnected {
            log.verbose("SYNC_DATA: Validating device connection to sync.")
            self.paymentDevice?.validateConnection(completion: { (isValid, error) in
                if let error = error {
                    self.syncFinished(error: error)
                    return
                }
                
                if isValid {
                    self.startSync()
                } else {
                    self.syncWithDeviceConnection()
                }
            })
            return nil
        }
        
        self.syncWithDeviceConnection()
        
        return nil
    }
    
    /**
     Tries to make sync with last user.
     
     If device disconnected, than system tries to connect.
     
     - parameter user: user from API to whom device belongs to.
     */
    open func tryToMakeSyncWithLastUser() -> NSError? {
        guard let user = self.user else {
            return NSError.error(code: SyncManager.ErrorCode.userIsNill, domain: SyncManager.self)
        }
        
        return sync(user, device: deviceInfo)
    }
    
    /**
     Completion handler
     
     - parameter event: Provides event with payload in eventData property
     */
    public typealias SyncEventBlockHandler = (_ event:FitpayEvent) -> Void
    
    /**
     Binds to the sync event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when system receives commit with eventType
     */
    @objc open func bindToSyncEvent(eventType: SyncEventType, completion: @escaping SyncEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    /**
     Binds to the sync event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when system receives commit with eventType
     - parameter queue: queue in which completion will be called
     */
    open func bindToSyncEvent(eventType: SyncEventType, completion: @escaping SyncEventBlockHandler, queue: DispatchQueue) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion, queue: queue), eventId: eventType)
    }				
    
    /**
     Removes bind.
     */
    open func removeSyncBinding(binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    /**
     Removes all synchronization bindings.
     */
    open func removeAllSyncBindings() {
        eventsDispatcher.removeAllBindings()
    }
    
    internal func syncWithDeviceConnection() {
        log.verbose("SYNC_DATA: No connection to device so connecting before initing sync.")
        if let binding = self.deviceConnectedBinding {
            self.paymentDevice!.removeBinding(binding: binding)
        }
        
        if let binding = self.deviceDisconnectedBinding {
            self.paymentDevice!.removeBinding(binding: binding)
        }
        
        self.deviceConnectedBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected, completion: {
            [unowned self] (event) in

            let deviceInfo = (event.eventData as? [String:Any])?["deviceInfo"] as? DeviceInfo
            let error = (event.eventData as? [String:Any])?["error"] as? Error

            guard (error == nil && deviceInfo != nil) else {
                
                self.callCompletionForSyncEvent(SyncEventType.connectingToDeviceCompleted, params: ["error": NSError.error(code: SyncManager.ErrorCode.cantConnectToDevice, domain: SyncManager.self)])
                
                self.syncFinished(error: NSError.error(code: SyncManager.ErrorCode.cantConnectToDevice, domain: SyncManager.self))
                
                return
            }

            self.callCompletionForSyncEvent(SyncEventType.connectingToDeviceCompleted)

            self.startSync()

            if let binding = self.deviceConnectedBinding {
                self.paymentDevice!.removeBinding(binding: binding)
            }

            self.deviceConnectedBinding = nil
        })
        
        self.deviceDisconnectedBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceDisconnected, completion: {
            [unowned self] (event) in
            self.callCompletionForSyncEvent(SyncEventType.syncFailed, params: ["error": NSError.error(code: SyncManager.ErrorCode.connectionWithDeviceWasLost, domain: SyncManager.self)])
            
            if let binding = self.deviceConnectedBinding {
                self.paymentDevice!.removeBinding(binding: binding)
            }
            
            if let binding = self.deviceDisconnectedBinding {
                self.paymentDevice!.removeBinding(binding: binding)
            }
            
            self.deviceConnectedBinding = nil
            self.deviceDisconnectedBinding = nil
        })
        
        self.paymentDevice!.connect(self.paymentDeviceConnectionTimeoutInSecs)
        
        self.callCompletionForSyncEvent(SyncEventType.connectingToDevice)
    }
    
    internal typealias ToWAPDUCommandsHandler = (_ cards:[CreditCard]?, _ error:Error?)->Void
    
    internal func getAllCardsWithToWAPDUCommands(_ completion:@escaping ToWAPDUCommandsHandler) {
        if self.user == nil {
            completion(nil, NSError.error(code: SyncManager.ErrorCode.unknownError, domain: SyncManager.self))
            return
        }
        
        self.user?.listCreditCards(excludeState: [""], limit: 20, offset: 0, completion: { (result, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if result!.nextAvailable {
                result?.collectAllAvailable({ (results, error) in
                    completion(results, error)
                })
            } else {
                completion(result?.results, error)
            }
        })
    }
    
    fileprivate func startSync() {
        log.verbose("SYNC_DATA: Sync preconditions validated, beginning process.")
        
        self.callCompletionForSyncEvent(SyncEventType.syncStarted)
        
        getCommits()
        {
            [unowned self] (commits, error) -> Void in
            
            guard (error == nil && commits != nil) else {
                log.error("SYNC_DATA: failed to get commits error: \(String(describing: error)).")
                self.syncFinished(error: NSError.error(code: SyncManager.ErrorCode.cantFetchCommits, domain: SyncManager.self))
                return
            }
            
            self.callCompletionForSyncEvent(.commitsReceived, params: ["commits":commits!])

            log.debug("SYNC_DATA: \(commits?.count ?? 0) commits successfully retrieved.")

            let applayerStarted = self.commitsApplyer.apply(commits!, completion:
            {
                [unowned self] (error) -> Void in
                
                if let _ = error {
                    log.error("SYNC_DATA: Commit applier returned a failure: \(String(describing: error))")
                    self.syncFinished(error: error)
                    return
                }

                log.verbose("SYNC_DATA: Commit applier returned with out errors.")
                
                self.syncFinished(error: nil)
                
                self.getAllCardsWithToWAPDUCommands({ [unowned self] (cards, error) in
                    if let error = error {
                        log.error("SYNC_DATA: Can't get offline APDU commands. Error: \(error)")
                        return
                    }
                    
                    if let cards = cards {
                        self.callCompletionForSyncEvent(SyncEventType.receivedCardsWithTowApduCommands, params: ["cards":cards])
                    }
                })
            })
            
            if !applayerStarted {
                self.syncFinished(error: NSError.error(code: SyncManager.ErrorCode.commitsApplyerIsBusy, domain: SyncManager.self))
            }
        }
    }
    
    fileprivate func obtainDeviceInfo(completion: @escaping (_ deviceInfo: DeviceInfo?, _ error: Error?)->Void) {
        // we already have device, return it
        if self.deviceInfo != nil {
            completion(self.deviceInfo, nil)
            return
        }
        
        // we should find device because we have no device
        findDeviceInfo(20, searchOffset: 0, completion: completion)
    }
    
    fileprivate func findDeviceInfo(_ itrSearchLimit: Int, searchOffset: Int, completion: @escaping (_ deviceInfo: DeviceInfo?, _ error: Error?)->Void) {
        user?.listDevices(limit: itrSearchLimit, offset: searchOffset, completion:
        {
            [unowned self] (result, error) -> Void in
            
            guard (error == nil && result != nil && result?.results?.count > 0) else {
                completion(nil, error)
                return
            }
            
            for deviceInfo in result!.results! {
                if deviceInfo.secureElementId != nil {
                    completion(deviceInfo, nil)
                    return
                }
            }
        
            if result!.results!.count + searchOffset >= result!.totalResults! {
                completion(nil, NSError.error(code: SyncManager.ErrorCode.cantFindDeviceWithSerialNumber, domain: SyncManager.self))
                return
            }
            
            self.findDeviceInfo(itrSearchLimit, searchOffset: searchOffset+itrSearchLimit, completion: completion)
        })
    }
    
    fileprivate func getCommits(_ completion: @escaping (_ commits: [Commit]?, _ error: Error?)->Void) {
        obtainDeviceInfo {
            [weak self] (deviceInfo, error) in
            
            if let deviceInfo = deviceInfo, let strongSelf = self {
                strongSelf.deviceInfo = deviceInfo

                let lastCommitId = strongSelf.syncStorage.getLastCommitId(strongSelf.deviceInfo!.deviceIdentifier!)

                deviceInfo.listCommits(commitsAfter: lastCommitId, limit: 20, offset: 0, completion:
                {
                    (result, error) -> Void in
                    
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    guard let result = result else {
                        completion(nil, NSError.unhandledError(SyncManager.self))
                        return
                    }
                    
                    if result.totalResults > result.results?.count {
                        result.collectAllAvailable(
                        {
                            (results, error) -> Void in
                            
                            if let error = error {
                                completion(nil, error)
                                return
                            }
                            
                            guard let results = results else {
                                completion(nil, NSError.unhandledError(SyncManager.self))
                                return
                            }
                            
                            completion(results, nil)
                        })
                    } else {
                        completion(result.results, nil)
                    }
                })
            } else {
                completion(nil, error)
            }
        }
    }

    internal func callCompletionForSyncEvent(_ event: SyncEventType, params: [String:Any] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: params))
    }

    fileprivate func syncFinished(error: Error?) {
        self.deviceInfo?.updateNotificationTokenIfNeeded()
        
        self.isSyncing = false

        if let error = error {
            log.debug("SYNC_DATA: Sync finished with error: \(error)")
            // TODO: it's a hack, because currently we can move to wallet screen only if we received SyncEventType.syncCompleted
            if (error as NSError).code == PaymentDevice.ErrorCode.tryLater.rawValue {
                callCompletionForSyncEvent(SyncEventType.syncCompleted, params: [:])
            } else {
                callCompletionForSyncEvent(SyncEventType.syncFailed, params: ["error": error])
            }
        } else {
            log.debug("SYNC_DATA: Sync finished successfully")
            callCompletionForSyncEvent(SyncEventType.syncCompleted, params: [:])
        }
        
        if let binding = self.deviceConnectedBinding {
            self.paymentDevice!.removeBinding(binding: binding)
        }
        
        if let binding = self.deviceDisconnectedBinding {
            self.paymentDevice!.removeBinding(binding: binding)
        }
        
        self.deviceConnectedBinding = nil
        self.deviceDisconnectedBinding = nil
    }

    internal func commitCompleted(_ commitId:String) {
        log.debug("SYNC_DATA: Setting new last commit ID(\(commitId)).")
        self.syncStorage.setLastCommitId(self.deviceInfo!.deviceIdentifier!, commitId: commitId)
    }
}


