import XCTest
import RxSwift
import RxBlocking

@testable import FitpaySDK

class MockSyncFactory: SyncFactory {
    var commitsFetcher: MockCommitsFetcher!
    
    func apduConfirmOperation() -> APDUConfirmOperationProtocol {
        return MockAPDUConfirm()
    }
    
    func nonApduConfirmOperation() -> NonAPDUConfirmOperationProtocol {
        return MockNonAPDUConfirm()
    }
    
    func commitsFetcherOperationWith(deviceInfo: Device, connector: PaymentDeviceConnectable?) -> FetchCommitsOperationProtocol {
        return commitsFetcher
    }
}
