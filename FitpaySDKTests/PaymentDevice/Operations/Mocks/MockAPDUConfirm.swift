import XCTest
import RxSwift
import RxBlocking

@testable import FitpaySDK

class MockAPDUConfirm: APDUConfirmOperationProtocol {
    func startWith(commit: Commit) -> Observable<Void> {
        return Observable.empty()
    }
}
