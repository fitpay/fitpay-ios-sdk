import Foundation

enum SyncRequestState: Int {
    case pending
    case inProgress
    case done
}

public typealias SyncRequestCompletion = (EventStatus, Error?) -> Void

open class SyncRequest {
    
    // MARK: - Public
    
    public let requestTime: Date
    public private(set) var syncStartTime: Date?
    
    public var syncInitiator: SyncInitiator?
    public var notificationAsc: NotificationDetail? {
        didSet {
            FitpayNotificationsManager.sharedInstance.updateRestClientForNotificationDetail(self.notificationAsc)
        }
    }
    
    /// Creates sync request.
    ///
    /// - Parameters:
    ///   - requestTime: time as Date object when request was made. Used for filtering unnecessary syncs. Defaults to Date().
    ///   - user: User object.
    ///   - deviceInfo: DeviceInfo object.
    ///   - paymentDevice: PaymentDevice object.
    ///   - initiator: syncInitiator Enum object. Defaults to .NotDefined.
    ///   - notificationAsc: NotificationDetail object.
    public init(requestTime: Date = Date(), user: User, deviceInfo: DeviceInfo, paymentDevice: PaymentDevice,
                initiator: SyncInitiator = .NotDefined, notificationAsc: NotificationDetail? = nil) {
        
        self.requestTime = requestTime
        self.user = user
        self.deviceInfo = deviceInfo
        self.paymentDevice = paymentDevice
        self.syncInitiator = initiator
        self.notificationAsc = notificationAsc
        
        // capture restClient reference
        if user.client != nil {
            self.restClient = user.client
        } else if deviceInfo.client != nil {
            self.restClient = deviceInfo.client
        }
    }
    
    // MARK: - Internal / Private
    
    internal var isEmptyRequest: Bool {
        return user == nil || deviceInfo == nil || paymentDevice == nil
    }
    
    internal var user: User?
    internal var deviceInfo: DeviceInfo?
    internal var paymentDevice: PaymentDevice?
    internal var completion: SyncRequestCompletion?
    
    private var state = SyncRequestState.pending
    
    // we should capture restClient to prevent deallocation
    private var restClient: RestClient?
    
    internal convenience init() {
        self.init(notificationAsc: nil, initiator: .NotDefined)
    }
    
    internal init(notificationAsc: NotificationDetail? = nil, initiator: SyncInitiator = .NotDefined) {
        self.requestTime = Date()
        self.user = nil
        self.deviceInfo = nil
        self.paymentDevice = nil
        self.syncInitiator = initiator
        self.notificationAsc = notificationAsc
        
        if SyncRequest.syncManager.synchronousModeOn == false {
            if (user != nil && deviceInfo != nil && paymentDevice != nil) == false {
                assert(false, "You should pass all params to SyncRequest in parallel sync mode.")
            }
        }
        
        // capture restClient reference
        if user?.client != nil {
            self.restClient = user?.client
        } else if deviceInfo?.client != nil {
            self.restClient = deviceInfo?.client
        }
    }
    
    internal static var syncManager: SyncManagerProtocol = SyncManager.sharedInstance
    
    internal func update(state: SyncRequestState) {
        if state == .inProgress {
            self.syncStartTime = Date()
        }
        
        self.state = state
    }
    
    internal func syncCompleteWith(status: EventStatus, error: Error?) {
        if let completion = self.completion {
            completion(status, error)
        }
    }
    
    internal func isSameUserAndDevice(otherRequest: SyncRequest) -> Bool {
        return user?.id == otherRequest.user?.id && deviceInfo?.deviceIdentifier == otherRequest.deviceInfo?.deviceIdentifier
    }
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "This constructor depreceted. You should use next one - init(requestTime: Date = Date(), user: User, deviceInfo: DeviceInfo, paymentDevice: PaymentDevice)")
    public init(initiator: SyncInitiator = .NotDefined, notificationAsc: NotificationDetail? = nil) {
        self.requestTime = Date()
        self.user = nil
        self.deviceInfo = nil
        self.paymentDevice = nil
        self.syncInitiator = initiator
        self.notificationAsc = notificationAsc

        if SyncRequest.syncManager.synchronousModeOn == false {
            if (user != nil && deviceInfo != nil && paymentDevice != nil) == false {
                assert(false, "You should pass all params to SyncRequest in parallel sync mode.")
            }
        }
        
        // capture restClient reference
        if user?.client != nil {
            self.restClient = user?.client
        } else if deviceInfo?.client != nil {
            self.restClient = deviceInfo?.client
        }
    }
    
}
