//
//  NotificationsManager.swift
//  FitpaySDK
//
//  Created by Anton on 19.08.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

import Foundation

public enum NotificationsType : String {
    case WithSync = "sync"
    case WithoutSync = "withoutsync"
}

public enum NotificationsEventType : Int, FitpayEventTypeProtocol {
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

open class FitpayNotificationsManager : NSObject {
    open static let sharedInstance = FitpayNotificationsManager()

    override public init() {
        super.init()
    }
    
    public typealias NotificationsPayload = [AnyHashable: Any]
    
    /**
     Handle notification from Fitpay platform. It may call syncing process and other stuff.
     When all notifications processed we should receive AllNotificationsProcessed event. In completion
     (or in other place where handling of hotification completed) to this event
     you should call fetchCompletionHandler if this function was called from background.
     
     - parameter payload: payload of notification
     */
    open func handleNotification(_ payload: NotificationsPayload) {
        log.verbose("--- handling notification ---")
        notificationsQueue.enqueue(payload)
        
        processNextNotificationIfAvailable()
    }
    
    /**
     Saves notification token after next sync process.
     
     - parameter token: notifications token which should be provided by Firebase
     */
    open func updateNotificationsToken(_ token: String) {
        notificationsToken = token
        
        SyncManager.sharedInstance.currentDeviceInfo?.updateNotificationTokenIfNeeded()
    }
    
    /**
     Completion handler
     
     - parameter event: Provides event with payload in eventData property
     */
    public typealias NotificationsEventBlockHandler = (_ event:FitpayEvent) -> Void
    
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
    
    // MARK: internal
    internal var notificationsToken : String = ""
    
    // MARK: private
    fileprivate let eventsDispatcher = FitpayEventDispatcher()
    fileprivate var syncCompletedBinding : FitpayEventBinding?
    fileprivate var syncFailedBinding : FitpayEventBinding?
    fileprivate var notificationsQueue = [NotificationsPayload]()
    fileprivate var currentNotification : NotificationsPayload?
    
    fileprivate func processNextNotificationIfAvailable() {
        log.verbose("--- [NotificationManager] processing next notification if available ---")
        guard currentNotification == nil else {
            print("--- currentNotification was nil returning ---")
            return
        }
        
        if notificationsQueue.peekAtQueue() == nil {
            log.verbose("--- [NotificationManager] peeked at queue and found nothing ---")
            self.callAllNotificationProcessedCompletion()
            return
        }
        
        self.currentNotification = notificationsQueue.dequeue()
        if let currentNotification = self.currentNotification {
            var notificationType = NotificationsType.WithoutSync

            if (currentNotification["fpField1"] as? String)?.lowercased() == "sync" {
                log.debug("--- [NotificationManager] notification was of type sync ---")
                notificationType = NotificationsType.WithSync
            }
            
            callReceivedCompletion(currentNotification, notificationType: notificationType)
            switch notificationType {
            case .WithSync:
                if let syncCompletedBinding = self.syncCompletedBinding {
                    log.verbose("--- [NotificationManager] notif manager removing sync binding ---")
                    SyncManager.sharedInstance.removeSyncBinding(binding: syncCompletedBinding)
                }
                syncCompletedBinding = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted, completion: { (event) in
                    log.debug("[NotificationManager] Sync from notification completed.")
                    self.currentNotification = nil
                    self.processNextNotificationIfAvailable()
                })
                
                if let syncFailedBinding = self.syncFailedBinding {
                    SyncManager.sharedInstance.removeSyncBinding(binding: syncFailedBinding)
                }
                syncFailedBinding = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed, completion: { (event) in
                    log.error("[NotificationManager] Sync from notification falied. Error: \((event.eventData as? [String:Any])?["error"])")
                    self.currentNotification = nil
                    self.processNextNotificationIfAvailable()
                })
                
                if let _ = SyncManager.sharedInstance.tryToMakeSyncWithLastUser() {
                    log.verbose("--- [NotificationManager] SyncManager.sharedInstance.tryToMakeSyncWithLastUser was not nil (WTF?) so processing next notif if available ---")
                    self.currentNotification = nil
                    self.processNextNotificationIfAvailable()
                }
                
                break
            case .WithoutSync: // just call completion
                log.debug("--- [NotificationManager] notif was non-sync ---")
                self.currentNotification = nil
                processNextNotificationIfAvailable()
                break
            }
        }
    }
    
    fileprivate func callReceivedCompletion(_ payload: NotificationsPayload, notificationType: NotificationsType) {
        var eventType : NotificationsEventType
        switch notificationType {
        case .WithSync:
            eventType = .receivedSyncNotification
            break
        case .WithoutSync:
            eventType = .receivedSimpleNotification
            break
        }
        
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: eventType, eventData: payload as AnyObject))
    }
    
    fileprivate func callAllNotificationProcessedCompletion() {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: NotificationsEventType.allNotificationsProcessed, eventData: [:]))
    }
}
