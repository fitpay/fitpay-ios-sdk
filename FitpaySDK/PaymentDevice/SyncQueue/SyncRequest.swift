import Foundation

public typealias SyncRequestCompletion = (EventStatus, Error?) -> Void

open class SyncRequest {
    
    static var syncManager: SyncManagerProtocol = SyncManager.sharedInstance

    public let requestTime: Date
    public let syncId: String?
    public private(set) var syncStartTime: Date?
    
    public var syncInitiator: SyncInitiator?
    public var notification: NotificationDetail? {
        didSet {
            FitpayNotificationsManager.sharedInstance.updateRestClientForNotificationDetail(self.notification)
        }
    }
    
    var isEmptyRequest: Bool {
        return user == nil || deviceInfo == nil || paymentDevice == nil
    }
    
    var user: User?
    var deviceInfo: Device?
    var paymentDevice: PaymentDevice?
    var completion: SyncRequestCompletion?
    
    private var state = SyncRequestState.pending
    
    // MARK: - Lifecycle
    
    /// Creates sync request.
    ///
    /// - Parameters:
    ///   - requestTime: time as Date object when request was made. Used for filtering unnecessary syncs. Defaults to Date().
    ///   - syncId: sync identifier used for not running duplicates
    ///   - user: User object.
    ///   - deviceInfo: DeviceInfo object.
    ///   - paymentDevice: PaymentDevice object.
    ///   - initiator: syncInitiator Enum object. Defaults to .NotDefined.
    ///   - notificationAsc: NotificationDetail object.
    public init(requestTime: Date = Date(), syncId: String? = nil, user: User, deviceInfo: Device, paymentDevice: PaymentDevice, initiator: SyncInitiator = .notDefined, notification: NotificationDetail? = nil) {
        self.requestTime = requestTime
        self.syncId = syncId
        self.user = user
        self.deviceInfo = deviceInfo
        self.paymentDevice = paymentDevice
        self.syncInitiator = initiator
        self.notification = notification
    }

    /// Create sync request from Notificatoin
    ///
    /// This can be created with no parameters but will never sync as a deviceId is required moving forward
    ///
    /// - Parameters:
    ///   - notification: Notification Detail created from a FitPay notification
    ///   - initiator: where the sync is coming from, defaulting to notification
    public init(notification: NotificationDetail? = nil, initiator: SyncInitiator = .notification, user: User? = nil) {
        self.requestTime = Date()
        self.syncId = notification?.syncId
        self.user = user
        let deviceInfo = Device()
        deviceInfo.deviceIdentifier = notification?.deviceId
        self.deviceInfo = deviceInfo
        self.paymentDevice = nil
        self.syncInitiator = initiator
        self.notification = notification
        
        if !SyncRequest.syncManager.synchronousModeOn && isEmptyRequest {
            assert(false, "You should pass all params to SyncRequest in parallel sync mode.")
        }
        
    }
    
    // MARK: - Internal Functions
    
    func update(state: SyncRequestState) {
        if state == .inProgress && syncStartTime == nil {
            syncStartTime = Date()
        }
        
        self.state = state
    }
    
    func syncCompleteWith(status: EventStatus, error: Error?) {
        completion?(status, error)
    }
    
    func isSameUserAndDevice(otherRequest: SyncRequest) -> Bool {
        return user?.id == otherRequest.user?.id && deviceInfo?.deviceIdentifier == otherRequest.deviceInfo?.deviceIdentifier
    }
    
}
