import Foundation

protocol SyncFactory {
    func commitsFetcherOperationWith(deviceInfo: Device, connector: PaymentDeviceConnectable?) -> FetchCommitsOperationProtocol
    func apduConfirmOperation() -> APDUConfirmOperationProtocol
    func nonApduConfirmOperation() -> NonAPDUConfirmOperationProtocol
    func connectDeviceOperationWith(paymentDevice: PaymentDevice) -> ConnectDeviceOperationProtocol
}

extension SyncFactory {
    func commitsFetcherOperationWith(deviceInfo: Device, connector: PaymentDeviceConnectable?) -> FetchCommitsOperationProtocol {
        return FetchCommitsOperation(deviceInfo: deviceInfo, shouldStartFromSyncedCommit: true, syncStorage: SyncStorage.sharedInstance, connector: connector)
    }
    
    func apduConfirmOperation() -> APDUConfirmOperationProtocol {
        return APDUConfirmOperation()
    }
    
    func nonApduConfirmOperation() -> NonAPDUConfirmOperationProtocol {
        return NonAPDUConfirmOperation()
    }
    
    func connectDeviceOperationWith(paymentDevice: PaymentDevice) -> ConnectDeviceOperationProtocol {
        return ConnectDeviceOperation(paymentDevice: paymentDevice)
    }
}

class DefaultSyncFactory: SyncFactory {}
