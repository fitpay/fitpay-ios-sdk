import RxSwift

protocol APDUConfirmOperationProtocol {
    func startWith(commit: Commit) -> Observable<Void>
}

class APDUConfirmOperation: APDUConfirmOperationProtocol {
    func startWith(commit: Commit) -> Observable<Void> {
        let publisher = PublishSubject<Void>()
        commit.confirmAPDU { (error) in
            guard error == nil else {
                publisher.onError(error!)
                return
            }
            
            publisher.onCompleted()
        }
        return publisher
    }
}
