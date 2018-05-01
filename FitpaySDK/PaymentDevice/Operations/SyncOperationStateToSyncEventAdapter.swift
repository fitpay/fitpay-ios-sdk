//
//  SyncOperationStateToSyncEventAdapter.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 11.07.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import RxSwift

class SyncOperationStateToSyncEventAdapter {
    
    init(stateObservable: Observable<SyncOperation.SyncOperationState>,
         publisher: PublishSubject<SyncEvent>) {
        self.stateObservable = stateObservable
        self.syncEventsPublisher = publisher
    }
    
    func startAdapting() -> Observable<SyncEvent> {
        self.stateObservable.subscribe(onNext: { [weak self] (state) in
            var callComplete = false
            var syncEvent: SyncEvent? = nil
            switch state {
            case .commitsReceived(let commits):
                syncEvent = SyncEvent(event: .commitsReceived, data: ["commits":commits])
                break
            case .completed(let error):
                if let error = error {
                    syncEvent = SyncEvent(event: .syncFailed, data: ["error": error])
                } else {
                    syncEvent = SyncEvent(event: .syncCompleted, data: [:])
                }
                callComplete = true
                break
            case .connected:
                syncEvent = SyncEvent(event: .connectingToDeviceCompleted, data: [:])
                break
            case .connecting:
                syncEvent = SyncEvent(event: .connectingToDevice, data: [:])
                break
            case .started:
                syncEvent = SyncEvent(event: .syncStarted, data: [:])
                break
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
    
    private var stateObservable: Observable<SyncOperation.SyncOperationState>
    private var syncEventsPublisher: PublishSubject<SyncEvent>
    private var disposeBag = DisposeBag()
}
