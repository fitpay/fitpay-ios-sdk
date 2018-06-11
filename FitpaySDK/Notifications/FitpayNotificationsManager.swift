import Foundation

public enum NotificationsType: String {
    case withSync = "sync"
    case withoutSync = "withoutsync"
}

public enum NotificationsEventType: Int, FitpayEventTypeProtocol {
    case receivedSyncNotification = 0x1
    case receivedSimpleNotification
    
    /**
     *  AllNotificationsProcessed event called when processing of notification finished e.g.
     *  sync with peyment device ect...
     *  If processing was done in background, than in completion for this event you should call
     *  fetchCompletionHandler from
     *  application(_:didReceiveRemoteNotification:fetchCompletionHandler:).
     */
    case allNotificationsProcessed
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .receivedSyncNotification:
            return "Received notification with sync operation"
        case .receivedSimpleNotification:
            return "Received simple notification without sync operation"
        case .allNotificationsProcessed:
            return "All notification processed"
        }
    }

}

open class FitpayNotificationsManager: NSObject {
    open static let sharedInstance = FitpayNotificationsManager()
    private var restClient: RestClient?
    
    public typealias NotificationsPayload = [AnyHashable: Any]
    public func setRestClient(_ client: RestClient?) {
        restClient = client
    }
    
    /**
     Handle notification from Fitpay platform. It may call syncing process and other stuff.
     When all notifications processed we should receive AllNotificationsProcessed event. In completion
     (or in other place where handling of hotification completed) to this event
     you should call fetchCompletionHandler if this function was called from background.
     
     - parameter payload: payload of notification
     */
    open func handleNotification(_ payload: NotificationsPayload) {
        log.verbose("--- handling notification ---")

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
        notificationsToken = token
        
        SyncRequestQueue.sharedInstance.lastFullSyncRequest?.deviceInfo?.updateNotificationTokenIfNeeded()
    }
    
    /**
     Completion handler
     
     - parameter event: Provides event with payload in eventData property
     */
    public typealias NotificationsEventBlockHandler = (_ event: FitpayEvent) -> Void
    
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
    
    open func updateRestClientForNotificationDetail(_ notificationDetail: NotificationDetail?) {
        if let notificationDetail = notificationDetail {
            if notificationDetail.restClient == nil {
                notificationDetail.restClient = self.restClient
            }
        }
    }

    // MARK: internal
    var notificationsToken: String = ""
    
    // MARK: private
    private let eventsDispatcher = FitpayEventDispatcher()
    private var syncCompletedBinding: FitpayEventBinding?
    private var syncFailedBinding: FitpayEventBinding?
    private var notificationsQueue = [NotificationsPayload]()
    private var currentNotification: NotificationsPayload?
    
    private func processNextNotificationIfAvailable() {
        log.verbose("NOTIFICATIONS_DATA: Processing next notification if available.")
        guard currentNotification == nil else {
            log.verbose("NOTIFICATIONS_DATA: currentNotification was nil returning.")
            return
        }
        
        if notificationsQueue.peekAtQueue() == nil {
            log.verbose("NOTIFICATIONS_DATA: peeked at queue and found nothing.")
            self.callAllNotificationProcessedCompletion()
            return
        }
        
        self.currentNotification = notificationsQueue.dequeue()
        if let currentNotification = self.currentNotification {
            var notificationType = NotificationsType.withoutSync

            if (currentNotification["fpField1"] as? String)?.lowercased() == "sync" {
                log.debug("NOTIFICATIONS_DATA: notification was of type sync.")
                notificationType = NotificationsType.withSync
            }
            
            callReceivedCompletion(currentNotification, notificationType: notificationType)
            switch notificationType {
            case .withSync:
                let notificationDetail = self.notificationDetailFromNotification(currentNotification)
                SyncRequestQueue.sharedInstance.add(request: SyncRequest(notificationAsc: notificationDetail, initiator: SyncInitiator.notification), completion: { (status, error) in
                    self.currentNotification = nil
                    self.processNextNotificationIfAvailable()
                })
                break
            case .withoutSync: // just call completion
                log.debug("NOTIFICATIONS_DATA: notif was non-sync.")
                self.currentNotification = nil
                processNextNotificationIfAvailable()
                break
            }
        }
    }
    
    private func callReceivedCompletion(_ payload: NotificationsPayload, notificationType: NotificationsType) {
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
    
    private func notificationDetailFromNotification(_ notification: NotificationsPayload?) -> NotificationDetail? {
        if let fpField2 = notification?["fpField2"] as? String {
            let notificationDetail = try? NotificationDetail(fpField2)
            notificationDetail?.restClient = self.restClient
            return notificationDetail
        }
        return nil
    }

}
