import XCTest
import RxSwift
import RxBlocking

@testable import FitpaySDK
class MockNonAPDUConfirm: NonAPDUConfirmOperationProtocol {
    func startWith(commit: Commit, result: NonAPDUCommitState) -> Observable<Void> {
        return Observable.empty()
    }
}
