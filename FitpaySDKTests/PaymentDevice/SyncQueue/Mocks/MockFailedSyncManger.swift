import XCTest

@testable import FitpaySDK

class MockFailedSyncManger: MockSyncManager {
    override func startSync(request: SyncRequest) {
        self.isSyncing = true
        
        DispatchQueue.main.asyncAfter(deadline: self.delayForSync) { [weak self] in
            self?.isSyncing = false
            self?.callCompletionForSyncEvent(.syncFailed, params: ["request": request, "error": NSError.unhandledError(MockFailedSyncManger.self)])
        }
    }
}
