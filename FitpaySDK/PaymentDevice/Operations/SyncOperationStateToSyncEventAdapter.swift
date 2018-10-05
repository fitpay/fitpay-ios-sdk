import Foundation
import RxSwift

class SyncOperationStateToSyncEventAdapter {
    
    private var stateObservable: Observable<SyncOperationState>
    private var syncEventsPublisher: PublishSubject<SyncEvent>
    
    private var disposeBag = DisposeBag()
    
    // MARK: - Lifecycle
    
    init(stateObservable: Observable<SyncOperationState>, publisher: PublishSubject<SyncEvent>) {
        self.stateObservable = stateObservable
        self.syncEventsPublisher = publisher
    }
    
    // MARK: - Functions
    
    func startAdapting() -> Observable<SyncEvent> {
        self.stateObservable.subscribe(onNext: { [weak self] (state) in
            var callComplete = false
            var syncEvent: SyncEvent?
            
            switch state {
            case .commitsReceived(let commits):
                syncEvent = SyncEvent(event: .commitsReceived, data: ["commits": commits])
            case .completed(let error):
                if let error = error {
                    syncEvent = SyncEvent(event: .syncFailed, data: ["error": error])
                } else {
                    syncEvent = SyncEvent(event: .syncCompleted, data: [:])
                }
                callComplete = true
            case .connected:
                syncEvent = SyncEvent(event: .connectingToDeviceCompleted, data: [:])
            case .connecting:
                syncEvent = SyncEvent(event: .connectingToDevice, data: [:])
            case .started:
                syncEvent = SyncEvent(event: .syncStarted, data: [:])
            case .waiting:
                break
            }
            
            if let syncEvent = syncEvent {
                self?.syncEventsPublisher.onNext(syncEvent)
            }
            
            if callComplete {
                self?.syncEventsPublisher.onCompleted()
            }
            
        }).disposed(by: disposeBag)
        
        return syncEventsPublisher
    }
    
}
