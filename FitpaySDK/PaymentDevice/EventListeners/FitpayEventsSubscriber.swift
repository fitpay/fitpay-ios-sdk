import Foundation

open class FitpayEventsSubscriber {
    
    public static var sharedInstance = FitpayEventsSubscriber()

    private let eventsDispatcher = FitpayEventDispatcher()

    private var subscribersWithBindings: [SubscriberWithBinding] = []
    
    public typealias EventCallback = (FitpayEvent) -> Void
    
    // MARK - Lifecycle
    
    private init() {
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardAdded) { event in
            self.executeCallbacksForEvent(event: .cardCreated)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardActivated) { event in
            self.executeCallbacksForEvent(event: .cardActivated)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardDeactivated) { event in
            self.executeCallbacksForEvent(event: .cardDeactivated)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardReactivated) { event in
            self.executeCallbacksForEvent(event: .cardReactivated)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardDeleted) { event in
            self.executeCallbacksForEvent(event: .cardDeleted)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .setDefaultCard) { event in
            self.executeCallbacksForEvent(event: .setDefaultCard)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .resetDefaultCard) { event in
            self.executeCallbacksForEvent(event: .resetDefaultCard)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardMetadataUpdated) { event in
            self.executeCallbacksForEvent(event: .cardMetadataUpdated)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .cardProvisionFailed) { event in
            self.executeCallbacksForEvent(event: .cardProvisionFailed)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .syncCompleted) { event in
            self.executeCallbacksForEvent(event: .syncCompleted)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .syncFailed) { event in
            var error: Error? = nil
            if let nserror = (event.eventData as? [String: NSError])?["error"] {
                error = SyncManager.ErrorCode(rawValue: nserror.code)
            }
            
            self.executeCallbacksForEvent(event: .syncCompleted, status: .failed, reason: error)
        }
        
        let _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: .apduPackageComplete) { event in
            
            var status = EventStatus.success
            var error: Error? = nil
            if let nserror = (event.eventData as? [String: NSError])?["error"] {
                error = SyncManager.ErrorCode(rawValue: nserror.code)
                status = .failed
            }
            
            self.executeCallbacksForEvent(event: .apduPackageProcessed, status: status, reason: error, eventData: event.eventData)
        }
    }
    
    // MARK: - Public Functions
    
    open func subscribeTo(event: EventType, subscriber: AnyObject, callback: @escaping EventCallback) {
        guard let binding = eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: callback), eventId: event) else {
            log.error("FitpayEventsSusbcriber: can't create event binding for event: \(event.eventDescription())")
            return
        }
        
        if var subscriberWithBindings = findSubscriberWithBindingsFor(subscriber: subscriber) {
            subscriberWithBindings.bindings.append(binding)
        } else {
            subscribersWithBindings.append(SubscriberWithBinding(subscriber: subscriber, bindings: [binding]))
        }
    }
    
    open func unsubscribe(subscriber: AnyObject) {
        var subscriberWithBindings: SubscriberWithBinding? = nil
        for (i, subscriberItr) in subscribersWithBindings.enumerated() {
            if subscriberItr.subscriber === subscriber {
                subscriberWithBindings = subscriberItr
                subscribersWithBindings.remove(at: i)
                break
            }
        }
        
        if let subscriberWithBindings = subscriberWithBindings {
            for binding in subscriberWithBindings.bindings {
    			self.unbind(binding)
            }
        }
    }
    
    open func unsubscribe(subscriber: AnyObject, event: EventType) {
        guard var subscriberWithBindings = findSubscriberWithBindingsFor(subscriber: subscriber) else {
            return
        }
        
        subscriberWithBindings.removeAllBindingsFor(event: event) {
            (binding) in
            self.unbind(binding)
        }
        
        removeSubscriberIfBindingsEmpty(subscriberWithBindings)
    }
    
    open func unsubscribe(subscriber: AnyObject, binding: FitpayEventBinding) {
        guard var subscriberWithBindings = findSubscriberWithBindingsFor(subscriber: subscriber) else {
            return
        }
        
        subscriberWithBindings.remove(binding: binding) {
            (binding) in
            self.unbind(binding)
        }
        
        removeSubscriberIfBindingsEmpty(subscriberWithBindings)
    }
    
    // MARK: - Internal Functions
    
    func executeCallbacksForEvent(event: EventType, status: EventStatus = .success, reason: Error? = nil, eventData: Any = "") {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: eventData, status: status, reason: reason))
    }
    
    // MARK: - Private Functions

    private func removeSubscriberIfBindingsEmpty(_ subscriberWithBinding: SubscriberWithBinding) {
        if subscriberWithBinding.bindings.count == 0 {
            for (i, subscriberItr) in subscribersWithBindings.enumerated() {
                if subscriberItr.subscriber === subscriberWithBinding.subscriber {
                    subscribersWithBindings.remove(at: i)
                    break
                }
            }
        }
    }
    
    private func unbind(_ binding: FitpayEventBinding) {
       eventsDispatcher.removeBinding(binding)
    }
    
    private func findSubscriberWithBindingsFor(subscriber: AnyObject) -> SubscriberWithBinding? {
        for subscriberItr in subscribersWithBindings {
            if subscriberItr.subscriber === subscriber {
                return subscriberItr
            }
        }
        
        return nil
    }

}

// MARK: - Nested Objects

extension FitpayEventsSubscriber{
    
    public enum EventType: Int, FitpayEventTypeProtocol {
        case cardCreated = 0
        case cardActivated
        case cardDeactivated
        case cardReactivated
        case cardDeleted
        case setDefaultCard
        case resetDefaultCard
        case cardProvisionFailed
        case cardMetadataUpdated
        
        case userCreated
        case getUserAndDevice
        
        case apduPackageProcessed
        case syncCompleted
        
        public func eventId() -> Int {
            return rawValue
        }
        
        public func eventDescription() -> String {
            switch self {
            case .cardCreated:
                return "Card created event."
            case .cardActivated:
                return "Card activated event."
            case .cardDeactivated:
                return "Card deactivated event."
            case .cardReactivated:
                return "Card reactivated event."
            case .cardDeleted:
                return "Card deleted event."
            case .setDefaultCard:
                return "Set default card event."
            case .resetDefaultCard:
                return "Reset default card event."
            case .cardProvisionFailed:
                return "Card provision failed event."
            case .cardMetadataUpdated:
                return "Card metadata updated event."
            case .userCreated:
                return "User created event."
            case .getUserAndDevice:
                return "Get user and device event."
            case .apduPackageProcessed:
                return "Apdu package processed event."
            case .syncCompleted:
                return "Sync completed event."
            }
        }
        
    }
    
    struct SubscriberWithBinding {
        weak var subscriber: AnyObject?
        var bindings: [FitpayEventBinding] = []
        
        mutating func removeAllBindingsFor(event: EventType, unBindBlock: (FitpayEventBinding) -> Void) {
            var eventsIndexForDelete: [Int] = []
            for (i, binding) in bindings.enumerated() {
                if binding.eventId.eventId() == event.eventId() {
                    unBindBlock(binding)
                    eventsIndexForDelete.append(i)
                }
            }
            
            for index in eventsIndexForDelete {
                bindings.remove(at: index)
            }
        }
        
        mutating func remove(binding: FitpayEventBinding, unBindBlock: (FitpayEventBinding) -> Void) {
            for (i, bindingItr) in bindings.enumerated() {
                if binding.eventId.eventId() == bindingItr.eventId.eventId() {
                    unBindBlock(binding)
                    bindings.remove(at: i)
                }
            }
        }
   
    }
    
}
