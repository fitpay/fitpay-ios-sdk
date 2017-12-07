//
//  SyncRequestsQueue.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 23.05.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation

open class SyncRequestQueue {
    public static let sharedInstance = SyncRequestQueue(syncManager: SyncManager.sharedInstance)
    
    public func add(request: SyncRequest, completion: SyncRequestCompletion?) {
        request.completion = completion
        request.update(state: .pending)

        guard let queue = queueFor(syncRequest: request) else {
            log.error("Error. Can't get/create sync request queue for device. Device id: \(request.deviceInfo?.deviceIdentifier ?? "nil")")
            request.update(state: .done)

            if let completion = completion {
                completion(.failed, NSError.unhandledError(SyncRequestQueue.self))
            }
            
            return
        }

        queue.add(request: request)
    }
    
    internal init(syncManager: SyncManagerProtocol) {
        self.syncManager = syncManager
        self.bind()
    }
    
    internal func updateLastEmptyRequestWith(request: SyncRequest) -> Bool{
        if let queue = self.queueFor(syncRequest: SyncRequest()) {
            if let intRequest = queue.dequeue() {
                add(request: request, completion: intRequest.completion)
                return true
            }
        }
        return false
    }

    deinit {
        self.unbind()
    }
    
    internal var requestsQueue: [SyncRequest] = []

    private typealias DeviceIdentifier = String
    private var queues: [DeviceIdentifier: BindedToDeviceSyncRequestQueue] = [:]
    private let syncManager: SyncManagerProtocol
    private var bindings: [FitpayEventBinding] = []

    private func queueFor(syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        let deviceId = syncRequest.deviceInfo?.deviceIdentifier ?? "none" // In this case we can also
                                                                          // process devices without id.
                                                                          // Do we need that?
        
        return queues[deviceId] ?? createNewQueueFor(deviceId: deviceId, syncRequest: syncRequest)
    }
    
    private func createNewQueueFor(deviceId: DeviceIdentifier, syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        let queue = BindedToDeviceSyncRequestQueue(deviceInfo: syncRequest.deviceInfo, syncManager: syncManager)
        queues[deviceId] = queue
        
        return queue
    }
    
    fileprivate func bind() {
        var binding = self.syncManager.bindToSyncEvent(eventType: .syncCompleted) { [weak self] (event) in
            guard let request = (event.eventData as? [String:Any])?["request"] as? SyncRequest else {
                log.warning("Can't get request from sync event.")
                return
            }
            
            if let queue = self?.queueFor(syncRequest: request) {
                queue.syncCompletedFor(request: request, withStatus: .success, andError: nil)
            }
        }
        
        if let binding = binding {
            self.bindings.append(binding)
        }
        
        binding = self.syncManager.bindToSyncEvent(eventType: .syncFailed) { [weak self] (event) in
            guard let request = (event.eventData as? [String:Any])?["request"] as? SyncRequest else {
                log.warning("Can't get request from sync event.")
                return
            }
            
            if let queue = self?.queueFor(syncRequest: request) {
                queue.syncCompletedFor(request: request, withStatus: .failed, andError: (event.eventData as? [String: Any])?["error"] as? NSError)
            }
        }
        
        if let binding = binding {
            self.bindings.append(binding)
        }
    }
    
    
    fileprivate func unbind() {
        for binding in self.bindings {
            self.syncManager.removeSyncBinding(binding: binding)
        }
    }
}
