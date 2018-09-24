import Foundation
import RxSwift

protocol FetchCommitsOperationProtocol {
    var deviceInfo: Device! { get set }
    
    func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]>
}

class FetchCommitsOperation: FetchCommitsOperationProtocol {
    
    var deviceInfo: Device!
    
    private var connector: PaymentDeviceConnectable?
    private let syncStorage: SyncStorage
    private let startFromSyncedCommit: Bool
    private let disposeBag = DisposeBag()
    
    private let publisher = PublishSubject<[Commit]>()
    
    init(deviceInfo: Device, shouldStartFromSyncedCommit: Bool = false, syncStorage: SyncStorage = SyncStorage.sharedInstance, connector: PaymentDeviceConnectable? = nil) {
        self.deviceInfo = deviceInfo
        self.startFromSyncedCommit = shouldStartFromSyncedCommit
        self.syncStorage = syncStorage
        self.connector = connector
    }
    
    func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]> {
        func loadCommits(afterCommit commitId: String) {
            deviceInfo.listCommits(commitsAfter: commitId, limit: limit, offset: offset) { [weak self] (result, error) in
                guard error == nil else {
                    self?.publisher.onError(error!)
                    return
                }
                
                guard let result = result else {
                    self?.publisher.onError(ErrorCode.parsingError)
                    return
                }
                
                let commits = result.results ?? []
                
                if result.nextAvailable {
                    result.collectAllAvailable { (results, error) in
                        guard error == nil else {
                            self?.publisher.onError(error!)
                            return
                        }
                        
                        guard let results = results else {
                            self?.publisher.onError(ErrorCode.parsingError)
                            return
                        }
                        
                        self?.publisher.onNext(results)
                    }
                } else {
                    self?.publisher.onNext(commits)
                }
            }
        }
        
        generateCommitIdFromWhichWeShouldStart().subscribe { [weak self] event in
            switch event {
            case .error(let error):
                self?.publisher.onError(error)
                return
            case .next(let commit):
                loadCommits(afterCommit: commit)
                return
            case .completed:
                break
            }
        }.disposed(by: disposeBag)
        
        return publisher
    }
    
    func generateCommitIdFromWhichWeShouldStart() -> Observable<String> {
        var commitId = ""
        if self.startFromSyncedCommit {
            if let getDeviceLastCommitId = self.connector?.getDeviceLastCommitId, self.connector?.setDeviceLastCommitId != nil {
                commitId = getDeviceLastCommitId()
            } else if let deviceId = self.deviceInfo.deviceIdentifier {
                commitId = self.syncStorage.getLastCommitId(deviceId)
            }
        }
        
        if commitId.isEmpty {
            return Observable.create({ [weak self] (observer) -> Disposable in
                self?.deviceInfo.lastAckCommit(completion: { (commit, error) in
                    if let error = error {
                        log.warning("SYNC_DATA: Can't get lastAckCommit. Error: \(error)")
                        // anyway continue sync process from beginning
                        observer.onNext("")
                    } else {
                        observer.onNext(commit?.commitId ?? "")
                    }
                    
                    observer.onCompleted()
                })
                
                return Disposables.create()
            })
        } else {
            return Observable.just(commitId)
        }

    }
    
}

// MARK: - Nested Objects

extension FetchCommitsOperation {
    enum ErrorCode: Error {
        case parsingError
    }
}
