
import ObjectMapper

@objc public enum SyncEventType : Int, FitpayEventTypeProtocol {
    case CONNECTING_TO_DEVICE = 0x1
    case CONNECTING_TO_DEVICE_FAILED
    case CONNECTING_TO_DEVICE_COMPLETED
    
    case SYNC_STARTED
    case SYNC_FAILED
    case SYNC_COMPLETED
    case SYNC_PROGRESS
    case APDU_COMMANDS_PROGRESS
    
    case COMMIT_PROCESSED

    case CARD_ADDED
    case CARD_DELETED
    case CARD_ACTIVATED
    case CARD_DEACTIVATED
    case CARD_REACTIVATED
    case SET_DEFAULT_CARD
    case RESET_DEFAULT_CARD
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .CONNECTING_TO_DEVICE:
            return "Connecting to device"
        case .CONNECTING_TO_DEVICE_FAILED:
            return "Connecting to device failed"
        case .CONNECTING_TO_DEVICE_COMPLETED:
            return "Connecting to device completed"
        case .SYNC_STARTED:
            return "Sync started"
        case .SYNC_FAILED:
            return "Sync failed"
        case .SYNC_COMPLETED:
            return "Sync completed"
        case .SYNC_PROGRESS:
            return "Sync progress"
        case .APDU_COMMANDS_PROGRESS:
            return "APDU progress"
        case .COMMIT_PROCESSED:
            return "Processed commit"
        case .CARD_ADDED:
            return "New card was added"
        case .CARD_DELETED:
            return "Card was deleted"
        case .CARD_ACTIVATED:
            return "Card was activated"
        case .CARD_DEACTIVATED:
            return "Card was deactivated"
        case .CARD_REACTIVATED:
            return "Card was reactivated"
        case .SET_DEFAULT_CARD:
            return "New default card was manually set"
        case .RESET_DEFAULT_CARD:
            return "New default card was automatically set"
        }
    }
}

public class SyncManager : NSObject {
    public static let sharedInstance = SyncManager()
    public var paymentDevice : PaymentDevice?
    
    
    internal let syncStorage : SyncStorage = SyncStorage()
    internal let paymentDeviceConnectionTimeoutInSecs : Int = 60
    
    private let eventsDispatcher = FitpayEventDispatcher()
    private var user : User?
    
    private var commitsApplyer = CommitsApplyer()
    private var currentDeviceId : String?
    
    private weak var deviceConnectedBinding : FitpayEventBinding?
    private weak var deviceDisconnectedBinding : FitpayEventBinding?
    
    private override init() {
        super.init()
    }
    
    public enum ErrorCode : Int, ErrorType, RawIntValue, CustomStringConvertible
    {
        case UnknownError                   = 0
        case CantConnectToDevice            = 10001
        case CantApplyAPDUCommand           = 10002
        case CantFetchCommits               = 10003
        case CantFindDeviceWithSerialNumber = 10004
        case SyncAlreadyStarted             = 10005
        case CommitsApplyerIsBusy           = 10006
        case ConnectionWithDeviceWasLost    = 10007
        
        public var description : String {
            switch self {
            case .UnknownError:
                return "Unknown error"
            case .CantConnectToDevice:
                return "Can't connect to payment device."
            case .CantApplyAPDUCommand:
                return "Can't apply APDU command to payment device."
            case .CantFetchCommits:
                return "Can't fetch commits from API."
            case .CantFindDeviceWithSerialNumber:
                return "Can't find device with serial number of connected payment device."
            case .SyncAlreadyStarted:
                return "Sync already started."
            case .CommitsApplyerIsBusy:
                return "Commits applyer is busy, sync already started?"
            case .ConnectionWithDeviceWasLost:
                return "Connection with device was lost."
            }
        }
    }
    
    public private(set) var isSyncing : Bool = false
    
    /**
     Starts sync process with payment device. 
     If device disconnected, than system tries to connect.
     
     - parameter user: user from API to whom device belongs to.
     */
    public func sync(user: User) -> NSError? {
        if self.isSyncing {
            return NSError.error(code: SyncManager.ErrorCode.SyncAlreadyStarted, domain: SyncManager.self)
        }
        
        self.isSyncing = true
        self.user = user
        
        if self.paymentDevice!.isConnected {
            startSync()
            return nil
        }
        
        if let binding = self.deviceConnectedBinding {
            self.paymentDevice!.removeBinding(binding: binding)
        }
        
        if let binding = self.deviceDisconnectedBinding {
            self.paymentDevice!.removeBinding(binding: binding)
        }
        
        self.deviceConnectedBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceConnected, completion:
        {
            [unowned self] (event) in
            
            let deviceInfo = event.eventData["deviceInfo"] as? DeviceInfo
            let error = event.eventData["error"] as? ErrorType
            
            guard (error == nil && deviceInfo != nil) else {
                
                self.callCompletionForSyncEvent(SyncEventType.CONNECTING_TO_DEVICE_COMPLETED, params: ["error": NSError.error(code: SyncManager.ErrorCode.CantConnectToDevice, domain: SyncManager.self)])
                
                self.syncFinished(error: NSError.error(code: SyncManager.ErrorCode.CantConnectToDevice, domain: SyncManager.self))
                
                return
            }
            
            self.callCompletionForSyncEvent(SyncEventType.CONNECTING_TO_DEVICE_COMPLETED)
            
            self.startSync()
            
            if let binding = self.deviceConnectedBinding {
                self.paymentDevice!.removeBinding(binding: binding)
            }
            
            self.deviceConnectedBinding = nil
        })
        
        self.deviceDisconnectedBinding = self.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceDisconnected, completion: {
            [unowned self] (event) in
            self.callCompletionForSyncEvent(SyncEventType.SYNC_FAILED, params: ["error": NSError.error(code: SyncManager.ErrorCode.ConnectionWithDeviceWasLost, domain: SyncManager.self)])
            
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
        
        self.callCompletionForSyncEvent(SyncEventType.CONNECTING_TO_DEVICE)
        
        return nil
    }
    
    /**
     Completion handler
     
     - parameter event: Provides event with payload in eventData property
     */
    public typealias SyncEventBlockHandler = (event:FitpayEvent) -> Void
    
    /**
     Binds to the sync event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when system receives commit with eventType
     */
    @objc public func bindToSyncEvent(eventType eventType: SyncEventType, completion: SyncEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    /**
     Binds to the sync event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when system receives commit with eventType
     - parameter queue: queue in which completion will be called
     */
    public func bindToSyncEvent(eventType eventType: SyncEventType, completion: SyncEventBlockHandler, queue: dispatch_queue_t) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion, queue: queue), eventId: eventType)
    }				
    
    /**
     Removes bind.
     */
    public func removeSyncBinding(binding binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    /**
     Removes all synchronization bindings.
     */
    public func removeAllSyncBindings() {
        eventsDispatcher.removeAllBindings()
    }
    
    private func startSync() {
        
        self.callCompletionForSyncEvent(SyncEventType.SYNC_STARTED)
        
        getCommits()
        {
            [unowned self] (commits, error) -> Void in
            
            guard (error == nil && commits != nil) else {
                self.syncFinished(error: NSError.error(code: SyncManager.ErrorCode.CantFetchCommits, domain: SyncManager.self))
                return
            }
            
//            TODO: this is for testing purposes only. It should be removed once actual APDU packages are being received
//            let cmts:[Commit]
//            if commits?.count > 0 {
//                cmts = self.___debug_appendAPDUCommits(commits!)
//            } else {
//                cmts = commits!
//            }

            let applayerStarted = self.commitsApplyer.apply(commits!, completion:
            {
                [unowned self] (error) -> Void in
                
                if let _ = error {
                    self.syncFinished(error: error)
                    return
                }
                
                self.syncFinished(error: nil)
            })
            
            if !applayerStarted {
                self.syncFinished(error: NSError.error(code: SyncManager.ErrorCode.CommitsApplyerIsBusy, domain: SyncManager.self))
            }
        }
    }
    
    private func findDeviceInfo(itrSearchLimit: Int, searchOffset: Int, completion:(deviceInfo: DeviceInfo?, error: ErrorType?)->Void) {
        //TODO: uncomment this once approved
        //let physicalDeviceInfo = self.paymentDevice.deviceInfo
        
        user?.listDevices(limit: itrSearchLimit, offset: searchOffset, completion:
        {
            [unowned self] (result, error) -> Void in
            
            guard (error == nil && result != nil && result?.results?.count > 0) else {
                completion(deviceInfo: nil, error: error)
                return
            }
            
            for deviceInfo in result!.results! {
                // TODO: uncomment this once approved
                // if deviceInfo.serialNumber == physicalDeviceInfo?.serialNumber {
                if deviceInfo.secureElementId != nil {
                    completion(deviceInfo: deviceInfo, error: nil)
                    return
                }
            }
        
            if result!.results!.count + searchOffset >= result!.totalResults! {
                completion(deviceInfo: nil, error: NSError.error(code: SyncManager.ErrorCode.CantFindDeviceWithSerialNumber, domain: SyncManager.self))
                return
            }
            
            self.findDeviceInfo(itrSearchLimit, searchOffset: searchOffset+itrSearchLimit, completion: completion)
        })
    }
    
    private func getCommits(completion: (commits: [Commit]?, error: ErrorType?)->Void) {
        findDeviceInfo(20, searchOffset: 0)
        {
            (deviceInfo, error) -> Void in
            
            if let deviceInfo = deviceInfo {
                self.currentDeviceId = deviceInfo.deviceIdentifier!

                let lastCommitId = self.syncStorage.getLastCommitId(self.currentDeviceId!)

                deviceInfo.listCommits(commitsAfter: lastCommitId, limit: 20, offset: 0, completion:
                {
                    (result, error) -> Void in
                    
                    if let error = error {
                        completion(commits: nil, error: error)
                        return
                    }
                    
                    guard let result = result else {
                        completion(commits: nil, error: NSError.unhandledError(SyncManager.self))
                        return
                    }
                    
                    if result.totalResults > result.results?.count {
                        result.collectAllAvailable(
                        {
                            (results, error) -> Void in
                            
                            if let error = error {
                                completion(commits: nil, error: error)
                                return
                            }
                            
                            guard let results = results else {
                                completion(commits: nil, error: NSError.unhandledError(SyncManager.self))
                                return
                            }
                            
                            completion(commits: results, error: nil)
                        })
                    } else {
                        completion(commits: result.results, error: nil)
                    }
                })
            } else {
                completion(commits: nil, error: error)
            }
        }
    }

    internal func callCompletionForSyncEvent(event: SyncEventType, params: [String:AnyObject] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: params))
    }

    private func syncFinished(error error: ErrorType?) {
        self.isSyncing = false
        self.currentDeviceId = nil
        
        if let error = error as? NSError {
            callCompletionForSyncEvent(SyncEventType.SYNC_FAILED, params: ["error": error])
        } else {
            callCompletionForSyncEvent(SyncEventType.SYNC_COMPLETED, params: [:])
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

    internal func commitCompleted(commitId:String) {
        self.syncStorage.setLastCommitId(self.currentDeviceId!, commitId: commitId)
    }
    
    //TODO: delete this once approved
    // debug
    private func ___debug_appendAPDUCommits(commits: [Commit]) -> [Commit] {
        var commit = commits.last!
        
        for commitItr in commits {
            if let _ = commitItr.commitType, let _ = commitItr.payload {
                commit = commitItr
                break
            }
        }
        let resourceLink = ResourceLink()
        resourceLink.href = "https://demo.pagare.me/apduPackages/baff08fb-0b73-5019-8877-7c490a43dc64/confirm"
        resourceLink.target = "apduResponse"
        commit.links?.append(resourceLink)
        
        commit.commitType = CommitType.APDU_PACKAGE
        let apduPackage = Mapper<ApduPackage>().map("{  \r\n   \"seIdType\":\"iccid\",\r\n   \"targetDeviceType\":\"fitpay.gandd.model.Device\",\r\n   \"targetDeviceId\":\"72425c1e-3a17-4e1a-b0a4-a41ffcd00a5a\",\r\n   \"packageId\":\"baff08fb-0b73-5019-8877-7c490a43dc64\",\r\n   \"seId\":\"333274689f09352405792e9493356ac880c44444442\",\r\n   \"targetAid\":\"8050200008CF0AFB2A88611AD51C\",\r\n   \"commandApdus\":[  \r\n      {  \r\n         \"commandId\":\"5f2acf6f-536d-4444-9cf4-7c83fdf394bf\",\r\n         \"groupId\":0,\r\n         \"sequence\":0,\r\n         \"command\":\"00E01234567890ABCDEF\",\r\n         \"type\":\"CREATE FILE\"\r\n      },\r\n      {  \r\n         \"commandId\":\"00df5f39-7627-447d-9380-46d8574e0643\",\r\n         \"groupId\":1,\r\n         \"sequence\":1,\r\n         \"command\":\"8050200008CF0AFB2A88611AD51C\",\r\n         \"type\":\"UNKNOWN\"\r\n      },\r\n      {  \r\n         \"commandId\":\"9c719928-8bb0-459c-b7c0-2bc48ec53f3c\",\r\n         \"groupId\":1,\r\n         \"sequence\":2,\r\n         \"command\":\"84820300106BBC29E6A224522E83A9B26FD456111500\",\r\n         \"type\":\"UNKNOWN\"\r\n      },\r\n      {  \r\n         \"commandId\":\"b148bea5-6d98-4c83-8a20-575b4edd7a42\",\r\n         \"groupId\":1,\r\n         \"sequence\":3,\r\n         \"command\":\"84F2200210F25397DCFB728E25FBEE52E748A116A800\",\r\n         \"type\":\"UNKNOWN\"\r\n      },\r\n      {  \r\n         \"commandId\":\"905fc5ab-4b15-4704-889b-2c5ffcfb2d68\",\r\n         \"groupId\":2,\r\n         \"sequence\":4,\r\n         \"command\":\"84F2200210F25397DCFB728E25FBEE52E748A116A800\",\r\n         \"type\":\"UNKNOWN\"\r\n      },\r\n      {  \r\n         \"commandId\":\"8e87ff12-dfc2-472a-bbf1-5f2e891e864c\",\r\n         \"groupId\":3,\r\n         \"sequence\":5,\r\n         \"command\":\"84F2200210F25397DCFB728E25FBEE52E748A116A800\",\r\n         \"type\":\"UNKNOWN\"\r\n      }\r\n   ],\r\n   \"validUntil\":\"2015-12-11T21:22:58.691Z\",\r\n   \"apduPackageUrl\":\"http://localhost:9103/transportservice/v1/apdupackages/baff08fb-0b73-5019-8877-7c490a43dc64\"\r\n}")
        apduPackage?.validUntilEpoch = 1559862740

        
        commit.payload?.apduPackage = apduPackage
        
        let apduPackages = [commit, commit, commit, commit, commit]
        
        return commits + apduPackages
    }
}


