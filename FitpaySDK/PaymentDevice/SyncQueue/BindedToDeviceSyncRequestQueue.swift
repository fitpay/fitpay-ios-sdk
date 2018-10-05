import Foundation

class BindedToDeviceSyncRequestQueue {
    
    private var requestsQueue: [SyncRequest] = []
    private var syncManager: SyncManagerProtocol
    
    // MARK: - Lifecycle
    
    init(syncManager: SyncManagerProtocol) {
        self.syncManager = syncManager
    }
    
    func add(request: SyncRequest) {
        let sizeOfQueue = requestsQueue.count
        
        requestsQueue.enqueue(request)
        
        var isSyncManagerBusy = false
        if syncManager.synchronousModeOn {
            isSyncManagerBusy = syncManager.isSyncing
        }
        
        if !isSyncManagerBusy && sizeOfQueue == 0 {
            if let error = startSyncFor(request: request) {
                syncCompletedFor(request: request, withStatus: .failed, andError: error)
            }
        }
    }
    
    func syncCompletedFor(request: SyncRequest, withStatus status: EventStatus, andError error: Error?) {
        guard let queuedRequest = requestsQueue.dequeue() else { return }
        guard queuedRequest.isSameUserAndDevice(otherRequest: request) else {
            log.error("SYNC_DATA: Error. Queued sync request is different from completed.")
            return
        }
        
        request.update(state: .done)
        request.syncCompleteWith(status: status, error: error)
        
        // outdated requests should also become completed, because we already processed their commits
        while let outdateRequest = self.requestsQueue.peekAtQueue() {
            guard outdateRequest.requestTime.timeIntervalSince1970 < request.syncStartTime!.timeIntervalSince1970 &&
                request.isSameUserAndDevice(otherRequest: outdateRequest) else {
                    break
            }
            
            _ = requestsQueue.dequeue()
            outdateRequest.update(state: .done)
            outdateRequest.syncCompleteWith(status: status, error: error)
            
        }
        
        processNext()
    }
    
    func dequeue() -> SyncRequest? {
        return requestsQueue.dequeue()
    }
    
    // MARK: - Private
    
    private func startSyncFor(request: SyncRequest) -> NSError? {
        request.update(state: .inProgress)
        
        var errorObj: NSError?
        if request.user != nil {
            do {
                try self.syncManager.syncWith(request: request)
            } catch {
                errorObj = error as NSError
            }
        } else {
            errorObj = NSError.error(code: 0, domain: BindedToDeviceSyncRequestQueue.self, message: "Can't start sync with empty user")
        }
        
        return errorObj
    }
    
    private func processNext() {
        guard let request = requestsQueue.peekAtQueue() else { return }
        
        if let error = startSyncFor(request: request) {
            syncCompletedFor(request: request, withStatus: .failed, andError: error)
        }
    }
    
}
