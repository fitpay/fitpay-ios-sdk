import Foundation
import RxSwift

public enum SyncOperationConnectionState {
    case connecting
    case connected
    case disconnected
}

protocol ConnectDeviceOperationProtocol {
    func start() -> Observable<SyncOperationConnectionState>
}

open class ConnectDeviceOperation: ConnectDeviceOperationProtocol {
    
    public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        self.publisher = BehaviorSubject<SyncOperationConnectionState>(value: .connecting)
    }
    
    open func start() -> Observable<SyncOperationConnectionState> {
        if self.paymentDevice.isConnected {
            log.verbose("SYNC_DATA: Validating device connection to sync.")
            
            publisher.onNext(.connected)
        } else {
            connect(observable: publisher)
        }
        
        return publisher
    }
    
    deinit {
        if let binding = self.deviceConnectedBinding {
            self.paymentDevice.removeBinding(binding: binding)
        }
        
        if let binding = self.deviceDisconnectedBinding {
            self.paymentDevice.removeBinding(binding: binding)
        }
        
        self.deviceConnectedBinding = nil
        self.deviceDisconnectedBinding = nil
    }
    
    static let paymentDeviceConnectionTimeoutInSecs: Int = 60

    // private
    private var paymentDevice: PaymentDevice
    // rx
    private var publisher: BehaviorSubject<SyncOperationConnectionState>
    // bindings
    private weak var deviceConnectedBinding : FitpayEventBinding?
    private weak var deviceDisconnectedBinding : FitpayEventBinding?
    
    private func connect(observable: BehaviorSubject<SyncOperationConnectionState>) {
        if let binding = self.deviceConnectedBinding {
            self.paymentDevice.removeBinding(binding: binding)
        }
        
        if let binding = self.deviceDisconnectedBinding {
            self.paymentDevice.removeBinding(binding: binding)
        }
        
        self.deviceConnectedBinding = self.paymentDevice.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected) {
            [weak self] (event) in
            
            let deviceInfo = (event.eventData as? [String:Any])?["deviceInfo"] as? DeviceInfo
            let error = (event.eventData as? [String:Any])?["error"] as? Error
            
            guard (error == nil && deviceInfo != nil) else {
                observable.onError(error ?? SyncOperationError.couldNotConnectToDevice)
                return
            }
            
            if let binding = self?.deviceConnectedBinding {
                self?.paymentDevice.removeBinding(binding: binding)
            }
            
            self?.deviceConnectedBinding = nil
            
            observable.onNext(.connected)
        }
        
        self.deviceDisconnectedBinding = self.paymentDevice.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceDisconnected, completion: {
            [weak self] (event) in
            
            if let binding = self?.deviceConnectedBinding {
                self?.paymentDevice.removeBinding(binding: binding)
            }
            
            if let binding = self?.deviceDisconnectedBinding {
                self?.paymentDevice.removeBinding(binding: binding)
            }
            
            self?.deviceConnectedBinding = nil
            self?.deviceDisconnectedBinding = nil
            
            observable.onNext(.disconnected)
        })
        
        self.paymentDevice.connect(ConnectDeviceOperation.paymentDeviceConnectionTimeoutInSecs)
        
        DispatchQueue.main.async {
            observable.onNext(.connecting)
        }
    }

}
