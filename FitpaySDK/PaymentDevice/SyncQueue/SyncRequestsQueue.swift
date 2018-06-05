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
    
    public func add(request: SyncRequest, payload: String? = nil, completion: SyncRequestCompletion?) {
        request.completion = completion
        if let payload = payload {
            if let notificationDetail = try? NotificationDetail(payload) {
                request.syncInitiator = .webHook
                request.notificationAsc = notificationDetail
            } else {
                log.error("Payload data is wrong. Payload: \(payload)")
            }
        }
        request.update(state: .pending)

        guard let queue = queueFor(syncRequest: request) else {
            log.error("Error. Can't get/create sync request queue for device. Device id: \(request.deviceInfo?.deviceIdentifier ?? "nil")")
            request.update(state: .done)

            if let completion = completion {
                completion(.failed, SyncRequestQueueError.cantCreateQueueForSyncRequest)
            }
            
            return
        }
        
        if !request.isEmptyRequest {
            lastFullSyncRequest = request
        }

        queue.add(request: request)
    }
    
    init(syncManager: SyncManagerProtocol) {
        self.syncManager = syncManager
        self.bind()
    }

    deinit {
        self.unbind()
    }
    
    private typealias DeviceIdentifier = String
    private var queues: [DeviceIdentifier: BindedToDeviceSyncRequestQueue] = [:]
    private let syncManager: SyncManagerProtocol
    private var bindings: [FitpayEventBinding] = []

    private func queueFor(syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        guard let deviceId = syncRequest.deviceInfo?.deviceIdentifier else {
            return queueForDeviceWithoutDeviceIdentifier(syncRequest: syncRequest)
        }
        
        return queues[deviceId] ?? createNewQueueFor(deviceId: deviceId, syncRequest: syncRequest)
    }
    
    private func createNewQueueFor(deviceId: DeviceIdentifier, syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        let queue = BindedToDeviceSyncRequestQueue(deviceInfo: syncRequest.deviceInfo, syncManager: syncManager)
        queues[deviceId] = queue
        
        return queue
    }
    
    private func queueForDeviceWithoutDeviceIdentifier(syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        log.warning("Searching queue for SyncRequest without deviceIdentifier (empty SyncRequests is deprecated)... ")
        guard let lastFullSyncRequest = self.lastFullSyncRequest else {
            log.error("Can't find queue for empty SyncRequest")
            return nil
        }
        
        syncRequest.user = lastFullSyncRequest.user
        syncRequest.deviceInfo = lastFullSyncRequest.deviceInfo
        syncRequest.paymentDevice = lastFullSyncRequest.paymentDevice
        
        log.warning("Putting SyncRequest without deviceIdentifier to the queue with deviceIdentifier - \(syncRequest.deviceInfo?.deviceIdentifier ?? "none")")
        return queueFor(syncRequest: syncRequest)
    }
    
    private func bind() {
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
    
    
    private func unbind() {
        for binding in self.bindings {
            self.syncManager.removeSyncBinding(binding: binding)
        }
    }
    
    var lastFullSyncRequest: SyncRequest?
}

extension SyncRequestQueue {
    enum SyncRequestQueueError: Error {
        case cantCreateQueueForSyncRequest
    }
}
