import Foundation

open class SyncRequestQueue {
    
    public static let sharedInstance = SyncRequestQueue(syncManager: SyncManager.sharedInstance)
    
    var paymentDevices: [PaymentDeviceStorage] = []
    
    private typealias DeviceIdentifier = String
    private var queues: [DeviceIdentifier: BindedToDeviceSyncRequestQueue] = [:]
    private let syncManager: SyncManagerProtocol
    private var bindings: [FitpayEventBinding] = []
    
    // MARK: - Lifecycle
    
    // used for dependency injection
    init(syncManager: SyncManagerProtocol) {
        self.syncManager = syncManager
        bind()
    }
    
    deinit {
        unbind()
    }

    // MARK: - Public Functions
    
    public func addPaymentDevice(user: User?, deviceInfo: Device?, paymentDevice: PaymentDevice?) {
        if !paymentDevices.contains(where: { $0.device?.deviceIdentifier == deviceInfo?.deviceIdentifier && $0.user?.id == user?.id }) {
            let device = PaymentDeviceStorage(paymentDevice: paymentDevice, user: user, device: deviceInfo)
            paymentDevices.append(device)
        }
    }
    
    public func removePaymentDevice(deviceId: String) {
        paymentDevices = paymentDevices.filter({ $0.device?.deviceIdentifier != deviceId })
    }
    
    public func add(request: SyncRequest, completion: SyncRequestCompletion?) {
        request.completion = completion
        request.update(state: .pending)
        
        guard let queue = queueFor(syncRequest: request) else {
            log.error("SYNC_DATA: Can't get/create sync request queue for device. Device id: \(request.deviceInfo?.deviceIdentifier ?? "nil")")
            request.update(state: .done)

            completion?(.failed, SyncRequestQueueError.cantCreateQueueForSyncRequest)
            
            return
        }
        
        if !request.isEmptyRequest {
            addPaymentDevice(user: request.user, deviceInfo: request.deviceInfo, paymentDevice: request.paymentDevice)
        }
        
        queue.add(request: request)
    }
    
    // MARK: - Private Functins
    
    private func queueFor(syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        guard let deviceId = syncRequest.deviceInfo?.deviceIdentifier else {
            log.warning("SYNC_DATA: Searching queue for SyncRequest without deviceIdentifier (empty SyncRequests is deprecated)... ")
            return queueForDeviceWithoutDeviceIdentifier(syncRequest: syncRequest)
        }
        
        return queues[deviceId] ?? createNewQueueFor(deviceId: deviceId, syncRequest: syncRequest)
    }
    
    private func createNewQueueFor(deviceId: DeviceIdentifier, syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        let queue = BindedToDeviceSyncRequestQueue(syncManager: syncManager)
        queues[deviceId] = queue
        
        return queue
    }
    
    private func queueForDeviceWithoutDeviceIdentifier(syncRequest: SyncRequest) -> BindedToDeviceSyncRequestQueue? {
        log.warning("SYNC_DATA: Searching queue for SyncRequest without deviceIdentifier (empty SyncRequests is deprecated)... ")
                
        guard let paymentDevice = paymentDevices.filter({ $0.device?.deviceIdentifier == syncRequest.notification?.deviceId }).first else { return nil }
        
        syncRequest.user = paymentDevice.user
        syncRequest.deviceInfo = paymentDevice.device
        syncRequest.paymentDevice = paymentDevice.paymentDevice
        
        log.warning("SYNC_DATA: Putting SyncRequest without deviceIdentifier to the queue with deviceIdentifier - \(syncRequest.deviceInfo?.deviceIdentifier ?? "none")")
        
        return queueFor(syncRequest: syncRequest)
    }
    
    private func bind() {
        var binding = self.syncManager.bindToSyncEvent(eventType: .syncCompleted) { [weak self] (event) in
            guard let request = (event.eventData as? [String: Any])?["request"] as? SyncRequest else {
                log.warning("SYNC_DATA: Can't get request from sync event.")
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
            guard let request = (event.eventData as? [String: Any])?["request"] as? SyncRequest else {
                log.warning("SYNC_DATA: Can't get request from sync event.")
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
    
}

extension SyncRequestQueue {
    enum SyncRequestQueueError: Error {
        case cantCreateQueueForSyncRequest
    }
}
