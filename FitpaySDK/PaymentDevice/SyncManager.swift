import ObjectMapper
import RxSwift

/**
 Completion handler
 
 - parameter event: Provides event with payload in eventData property
 */
public typealias SyncEventBlockHandler = (_ event:FitpayEvent) -> Void

protocol SyncManagerProtocol {
    func syncWith(request: SyncRequest) throws
    
    var isSyncing: Bool { get }
    var synchronousModeOn: Bool { get }
    
    func bindToSyncEvent(eventType: SyncEventType, completion: @escaping SyncEventBlockHandler) -> FitpayEventBinding?
    func removeSyncBinding(binding: FitpayEventBinding)
    func callCompletionForSyncEvent(_ event: SyncEventType, params: [String: Any])
}

@objcMembers
open class SyncManager : NSObject, SyncManagerProtocol {
    open static let sharedInstance = SyncManager(syncFactory: DefaultSyncFactory())
    open var synchronousModeOn = true
    
    @available(*, deprecated, message: "use SyncRequestQueue: instead")
    open var paymentDevice : PaymentDevice?
    
    @available(*, deprecated, message: "you can use lastSyncRequest instead")
    open var userId : String? {
        return user?.id
    }
    
    @available(*, deprecated, message: "you can use lastSyncRequest instead")
    public private(set) var deviceInfo : DeviceInfo?

    
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
        case notEnoughData                  = 10009
        
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
            case .notEnoughData:
                return "For sync we need user, deviceInfo, paymentDevice, connector - some of that values is missing."
            }
        }
    }
    
    open private(set) var isSyncing : Bool = false
    
    /**
     Starts sync process with payment device.
     If device disconnected, than system tries to connect.
     
     - parameter user:	 user from API to whom device belongs to.
     - parameter device: device which we will sync with. If nil then we will use first one with secureElemendId.
     */
    @available(*, deprecated, message: "use SyncRequestQueue: instead")
    open func sync(_ user: User, device: DeviceInfo? = nil, deviceConnector: IPaymentDeviceConnector? = nil) -> NSError? {
        log.debug("SYNC_DATA: Starting sync.")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        guard !self.isSyncing else {
            log.warning("SYNC_DATA: Already syncing so can't sync.")
            return NSError.error(code: SyncManager.ErrorCode.syncAlreadyStarted, domain: SyncManager.self)
        }
        
        guard let device = device, let paymentDevice = self.paymentDevice else {
            return NSError.error(code: SyncManager.ErrorCode.notEnoughData, domain: SyncManager.self)
        }
        
        self.isSyncing = true
        self.user = user
        self.deviceInfo = device
        
        if let deviceConnector = deviceConnector {
            if let error = self.paymentDevice?.changeDeviceInterface(deviceConnector) {
                return error
            }
        }
        
        do {
            try syncWith(request: SyncRequest(user: user, deviceInfo: device, paymentDevice: paymentDevice))
        } catch {
            return error as NSError
        }
        
        return nil
    }
    
    /**
     Tries to make sync with last user.
     
     If device disconnected, than system tries to connect.
     
     - parameter user: user from API to whom device belongs to.
     */
    @available(*, deprecated, message: "use SyncRequestQueue: instead")
    open func tryToMakeSyncWithLastUser() -> NSError? {
        guard let user = self.user else {
            return NSError.error(code: SyncManager.ErrorCode.userIsNill, domain: SyncManager.self)
        }
        
        return sync(user, device: deviceInfo)
    }
    
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
    
    open var commitFetcherOperationProducer: () -> FetchCommitsOperationProtocol? = {
        return FetchCommitsOperation(deviceInfo: DeviceInfo())
    }
    
    var syncFactory: SyncFactory
    var syncStorage: SyncStorage

    internal let paymentDeviceConnectionTimeoutInSecs : Int = 60
    
    internal func syncWith(request: SyncRequest) throws {
        if synchronousModeOn {
            if syncOperations.count > 0 {
                throw ErrorCode.syncAlreadyStarted
            }
        }
        
        if let deviceInfo = request.deviceInfo {
            if syncOperations[deviceInfo] != nil {
                throw ErrorCode.syncAlreadyStarted
            }
        }
        
        do {
            try self.startSyncWith(request: request)
        } catch {
            throw error
        }
    }
    
    private func startSyncWith(request: SyncRequest) throws {
        guard let paymentDevice = request.paymentDevice,
            let connector = request.paymentDevice?.deviceInterface,
            let deviceInfo = request.deviceInfo,
            let user = request.user else {
                throw ErrorCode.notEnoughData
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let syncOperation = SyncOperation(paymentDevice: paymentDevice,
                                          connector: connector,
                                          deviceInfo: deviceInfo,
                                          user: user,
                                          syncFactory: syncFactory,
                                          syncStorage: syncStorage,
                                          request: request)
        
        syncOperations[deviceInfo] = syncOperation
        
        syncOperation.start().subscribe(onNext: { [unowned self] (event) in
            
            switch event.event {
            case .syncCompleted:
                self.syncFinishedFor(request: request, withError: nil)
                self.syncOperations.removeValue(forKey: deviceInfo)
                break
            case .syncFailed:
                self.syncFinishedFor(request: request, withError: event.data["error"] as? Error)
                self.syncOperations.removeValue(forKey: deviceInfo)
                break
            default:
                self.callCompletionForSyncEvent(event.event, params: event.data)
            }
            
        }).disposed(by: disposeBag)
    }
    
    private var syncOperations = [DeviceInfo:SyncOperation]()
    private var disposeBag = DisposeBag()
    
    private let eventsDispatcher = FitpayEventDispatcher()
    private var user: User?
    
    internal init(syncFactory: SyncFactory, syncStorage: SyncStorage = SyncStorage.sharedInstance) {
        self.syncFactory = syncFactory
        self.syncStorage = syncStorage
        super.init()
    }
    
    internal func callCompletionForSyncEvent(_ event: SyncEventType, params: [String:Any] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: params))
    }

    internal typealias ToWAPDUCommandsHandler = (_ cards:[CreditCard]?, _ error:Error?)->Void
    
    internal func getAllCardsWithToWAPDUCommands(user: User?,_ completion:@escaping ToWAPDUCommandsHandler) {
        if user == nil {
            completion(nil, NSError.error(code: SyncManager.ErrorCode.unknownError, domain: SyncManager.self))
            return
        }
    
        user?.listCreditCards(excludeState: [""], limit: 20, offset: 0, completion: { (result, error) in
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
    
    private func syncFinishedFor(request: SyncRequest, withError error: Error?) {
        self.isSyncing = false
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
            log.debug("SYNC_DATA: Sync finished successfully")
            callCompletionForSyncEvent(SyncEventType.syncCompleted, params: eventParams)
        }
        
        self.getAllCardsWithToWAPDUCommands(user: request.user) { [unowned self] (cards, error) in
            if let error = error {
                log.error("SYNC_DATA: Can't get offline APDU commands. Error: \(error)")
                return
            }

            if let cards = cards {
                self.callCompletionForSyncEvent(SyncEventType.receivedCardsWithTowApduCommands, params: ["cards":cards])
            }
        }
    }
}

