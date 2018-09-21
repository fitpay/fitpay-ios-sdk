import Foundation

open class FitpayNotificationsManager: NSObject, ClientModel {
    
    public static let sharedInstance = FitpayNotificationsManager()
    
    public typealias NotificationsPayload = [AnyHashable: Any]
    
    /// NotificationsEventBlockHandler
    ///
    /// - parameter event: Provides event with payload in eventData property
    public typealias NotificationsEventBlockHandler = (_ event: FitpayEvent) -> Void
    
    var notificationToken: String = ""
    var client: RestClient?

    private let eventsDispatcher = FitpayEventDispatcher()
    private var syncCompletedBinding: FitpayEventBinding?
    private var syncFailedBinding: FitpayEventBinding?
    private var notificationsQueue = [NotificationsPayload]()
    private var currentNotification: NotificationsPayload?
    

    
    // MARK - Public Functions
    public func setRestClient(_ client: RestClient?) {
        self.client = client
    }
    
    /**
     Handle notification from Fitpay platform. It may call syncing process and other stuff.
     When all notifications processed we should receive AllNotificationsProcessed event. In completion
     (or in other place where handling of hotification completed) to this event
     you should call fetchCompletionHandler if this function was called from background.
     
     - parameter payload: payload of notification
     */
    open func handleNotification(_ payload: NotificationsPayload) {
        log.verbose("NOTIFICATIONS_DATA: handling notification")
        
        let notificationDetail = self.notificationDetailFromNotification(payload)
        notificationDetail?.sendAckSync()
        
        notificationsQueue.enqueue(payload)
        
        processNextNotificationIfAvailable()
    }
    
    /**
     Saves notification token after next sync process.
     
     - parameter token: notifications token which should be provided by Firebase
     */
    open func updateNotificationsToken(_ token: String) {
        notificationToken = token
    }
    
    /**
     Binds to the event using NotificationsEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called
     */
    open func bindToEvent(eventType: NotificationsEventType, completion: @escaping NotificationsEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    /**
     Binds to the event using NotificationsEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called
     - parameter queue: queue in which completion will be called
     */
    open func bindToEvent(eventType: NotificationsEventType, completion: @escaping NotificationsEventBlockHandler, queue: DispatchQueue) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion, queue: queue), eventId: eventType)
    }
    
    /// Removes bind.
    open func removeSyncBinding(binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    /// Removes all synchronization bindings.
    open func removeAllSyncBindings() {
        eventsDispatcher.removeAllBindings()
    }
    
    open func updateRestClientForNotificationDetail(_ notificationDetail: NotificationDetail?) {
        if let notificationDetail = notificationDetail, notificationDetail.client == nil {
            notificationDetail.client = self.client
        }
    }
    
    /// Creates a notification detail from both old and new notification types
    public func notificationDetailFromNotification(_ notification: NotificationsPayload?) -> NotificationDetail? {
        var notificationDetail: NotificationDetail?
        if let fpField2 = notification?["fpField2"] as? String {
            notificationDetail = try? NotificationDetail(fpField2)
            
        } else if notification?["source"] as? String == "FitPay" {
            notificationDetail = try? NotificationDetail(notification?["payload"])
        }
        
        notificationDetail?.client = self.client
        return notificationDetail
    }
    
    // MARK: - Private Functions
    
    private func processNextNotificationIfAvailable() {
        log.verbose("NOTIFICATIONS_DATA: Processing next notification if available.")
        guard currentNotification == nil else {
            log.verbose("NOTIFICATIONS_DATA: currentNotification was not nil returning.")
            return
        }
        
        if notificationsQueue.peekAtQueue() == nil {
            log.verbose("NOTIFICATIONS_DATA: peeked at queue and found nothing.")
            callAllNotificationProcessedCompletion()
            return
        }
        
        currentNotification = notificationsQueue.dequeue()
        guard let currentNotification = self.currentNotification else { return }
        
        var notificationType = NotificationType.withoutSync
        
        if (currentNotification["fpField1"] as? String)?.lowercased() == "sync" {
            log.debug("NOTIFICATIONS_DATA: notification was of type sync.")
            notificationType = NotificationType.withSync
        }
        
        callReceivedCompletion(currentNotification, notificationType: notificationType)
        switch notificationType {
        case .withSync:
            let notificationDetail = notificationDetailFromNotification(currentNotification)
            SyncRequestQueue.sharedInstance.add(request: SyncRequest(notification: notificationDetail, initiator: .notification)) { (status, error) in
                self.currentNotification = nil
                self.processNextNotificationIfAvailable()
            }
            break
        case .withoutSync: // just call completion
            log.debug("NOTIFICATIONS_DATA: notification was non-sync.")
            self.currentNotification = nil
            processNextNotificationIfAvailable()
            break
        }
    }
    
    private func callReceivedCompletion(_ payload: NotificationsPayload, notificationType: NotificationType) {
        var eventType: NotificationsEventType
        switch notificationType {
        case .withSync:
            eventType = .receivedSyncNotification
            break
        case .withoutSync:
            eventType = .receivedSimpleNotification
            break
        }
        
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: eventType, eventData: payload))
    }
    
    private func callAllNotificationProcessedCompletion() {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: NotificationsEventType.allNotificationsProcessed, eventData: [:]))
    }
    
}
