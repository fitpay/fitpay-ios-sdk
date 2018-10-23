import RxSwift

/**
 Completion handler
 
 - parameter event: Provides event with payload in eventData property
 */
public typealias SyncEventBlockHandler = (_ event: FitpayEvent) -> Void

protocol SyncManagerProtocol {
    
    var isSyncing: Bool { get }
    var synchronousModeOn: Bool { get }
    
    func syncWith(request: SyncRequest) throws
    func bindToSyncEvent(eventType: SyncEventType, completion: @escaping SyncEventBlockHandler) -> FitpayEventBinding?
    func removeSyncBinding(binding: FitpayEventBinding)
    func callCompletionForSyncEvent(_ event: SyncEventType, params: [String: Any])
    
}

@objcMembers open class SyncManager: NSObject, SyncManagerProtocol {
    
    public static let sharedInstance = SyncManager(syncFactory: DefaultSyncFactory())
    
    open var synchronousModeOn = true
    open private(set) var isSyncing = false

    var syncFactory: SyncFactory
    var syncStorage: SyncStorage
    
    var commitFetcherOperationProducer: () -> FetchCommitsOperationProtocol? = {
        return FetchCommitsOperation(deviceInfo: Device())
    }
    
    let paymentDeviceConnectionTimeoutInSecs = 60
    
    private var syncedIds: [String] = []
    private var syncOperations = [Device: SyncOperation]()
    private var disposeBag = DisposeBag()
    private var user: User?
    
    private let eventsDispatcher = FitpayEventDispatcher()
    
    typealias ToWAPDUCommandsHandler = (_ cards: [CreditCard]?, _ error: Error?) -> Void

    // MARK: - Lifecycle
    
    init(syncFactory: SyncFactory, syncStorage: SyncStorage = SyncStorage.sharedInstance) {
        self.syncFactory = syncFactory
        self.syncStorage = syncStorage
        super.init()
    }
    
    // MARK: - Public Functions

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
    
    // MARK: - Internal Functions

    func syncWith(request: SyncRequest) throws {
        if synchronousModeOn && syncOperations.count > 0 {
            throw ErrorCode.syncAlreadyStarted
        }
        
        if let deviceId = request.notification?.deviceId, let userId = request.notification?.userId {
            if deviceId != request.deviceInfo?.deviceIdentifier && userId != request.user?.id {
                  throw ErrorCode.cantConnectToDevice
            }
        }       
        
        if let deviceInfo = request.deviceInfo, syncOperations[deviceInfo] != nil {
            throw ErrorCode.syncAlreadyStarted
        }
        
        do {
            try startSyncWith(request: request)
        } catch {
            throw error
        }
    }

    func callCompletionForSyncEvent(_ event: SyncEventType, params: [String: Any] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: params))
    }
    
    func getAllCardsWithToWAPDUCommands(user: User?, _ completion: @escaping ToWAPDUCommandsHandler) {
        if user == nil {
            completion(nil, NSError.error(code: SyncManager.ErrorCode.unknownError, domain: SyncManager.self))
            return
        }
        
        user?.getCreditCards(excludeState: [""], limit: 20, offset: 0) { (result, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if result!.nextAvailable {
                result?.collectAllAvailable { (results, error) in
                    completion(results, error)
                }
            } else {
                completion(result?.results, error)
            }
        }
    }
    
    // MARK: - Private Functions
    
    private func startSyncWith(request: SyncRequest) throws {
        guard let paymentDevice = request.paymentDevice,
            let connector = request.paymentDevice?.deviceInterface,
            let deviceInfo = request.deviceInfo,
            let user = request.user else {
                throw ErrorCode.notEnoughData
        }
                
        if let syncId = request.syncId {
            if syncedIds.contains(syncId) {
                throw ErrorCode.syncAlreadyStarted
            }
            syncedIds.append(syncId)
        }
        
        log.debug("SYNC_DATA: Sync started for device id: \(String(describing: request.deviceInfo?.deviceIdentifier))")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let syncOperation = SyncOperation(paymentDevice: paymentDevice,
                                          connector: connector,
                                          deviceInfo: deviceInfo,
                                          user: user,
                                          syncFactory: syncFactory,
                                          syncStorage: syncStorage,
                                          syncRequest: request)
        
        syncOperations[deviceInfo] = syncOperation
        
        syncOperation.start().subscribe(onNext: { [unowned self] event in
            
            switch event.event {
            case .syncCompleted:
                self.syncFinishedFor(request: request, withError: nil)
                self.syncOperations.removeValue(forKey: deviceInfo)
            case .syncFailed:
                self.syncFinishedFor(request: request, withError: event.data["error"] as? Error)
                self.syncOperations.removeValue(forKey: deviceInfo)
            default:
                self.callCompletionForSyncEvent(event.event, params: event.data)
            }
            
        }).disposed(by: disposeBag)
    }
    
    private func syncFinishedFor(request: SyncRequest, withError error: Error?) {
        isSyncing = false
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        var eventParams: [String: Any] = ["request": request]
        
        if let error = error {
            log.debug("SYNC_DATA: Sync finished with error: \(error)")
            // TODO: it's a hack, because currently we can move to wallet screen only if we received SyncEventType.syncCompleted
            if (error as NSError).code == PaymentDevice.ErrorCode.tryLater.rawValue {
                callCompletionForSyncEvent(SyncEventType.syncCompleted, params: eventParams)
            } else {
                eventParams["error"] = error
                callCompletionForSyncEvent(SyncEventType.syncFailed, params: eventParams)
            }
        } else {
            log.debug("SYNC_DATA: Sync finished successfully. Device id: \(String(describing: request.deviceInfo?.deviceIdentifier))")
            callCompletionForSyncEvent(SyncEventType.syncCompleted, params: eventParams)
        }
        
        self.getAllCardsWithToWAPDUCommands(user: request.user) { [unowned self] (cards, error) in
            if let error = error {
                log.error("SYNC_DATA: Can't get offline APDU commands. Error: \(error)")
                return
            }
            
            if let cards = cards {
                self.callCompletionForSyncEvent(SyncEventType.receivedCardsWithTowApduCommands, params: ["cards": cards])
            }
        }
    }

}

// MARK: - Nested Functions

extension SyncManager {
    
    public enum ErrorCode: Int, Error, RawIntValue, CustomStringConvertible {
        case unknownError                   = 0
        case cantConnectToDevice            = 10001
        case cantApplyAPDUCommand           = 10002
        case cantFetchCommits               = 10003
        case cantFindDeviceWithSerialNumber = 10004
        case syncAlreadyStarted             = 10005
        case commitsApplyerIsBusy           = 10006
        case connectionWithDeviceWasLost    = 10007
        case userIsNil                     = 10008
        case notEnoughData                  = 10009
        
        public var description: String {
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
            case .userIsNil:
                return "User is nil"
            case .notEnoughData:
                return "For sync we need user, deviceInfo, paymentDevice, connector - some of that values is missing."
            }
        }
    }
    
}
