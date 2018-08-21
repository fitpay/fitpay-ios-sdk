import XCTest

@testable import FitpaySDK

class MockSyncManager: SyncManagerProtocol {
    var synchronousModeOn: Bool = true
    var isSyncing: Bool = false
    
    static var syncCompleteDelay: Double = 0.2
    
    private let eventsDispatcher = FitpayEventDispatcher()
    
    private var lastSyncRequest: SyncRequest?
    
    func syncWith(request: SyncRequest) throws {
        if isSyncing && synchronousModeOn {
            throw NSError.unhandledError(MockSyncManager.self)
        }
        
        lastSyncRequest = request
        
        self.startSync(request: request)
    }
    
    func syncWithLastRequest() throws {
        guard let lastSyncRequest = self.lastSyncRequest else {
            throw NSError.unhandledError(MockSyncManager.self)
        }
        
        if isSyncing && synchronousModeOn {
            throw NSError.unhandledError(MockSyncManager.self)
        }
        
        self.startSync(request: lastSyncRequest)
    }
    
    func bindToSyncEvent(eventType: SyncEventType, completion: @escaping SyncEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    func removeSyncBinding(binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    func callCompletionForSyncEvent(_ event: SyncEventType, params: [String: Any]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: event, eventData: params))
    }
    
    func startSync(request: SyncRequest) {
        self.isSyncing = true
        
        DispatchQueue.main.asyncAfter(deadline: self.delayForSync) { [weak self] in
            self?.isSyncing = false
            self?.callCompletionForSyncEvent(.syncCompleted, params: ["request":request])
        }
    }
    
    var delayForSync: DispatchTime {
        return .now() + MockSyncManager.syncCompleteDelay
    }
}
