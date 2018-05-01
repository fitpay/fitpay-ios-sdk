//
//  FetchCommitsOperation.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 12.07.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation
import RxSwift

public protocol FetchCommitsOperationProtocol {
    var deviceInfo: DeviceInfo! { get set }
    
    func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]>
}

open class FetchCommitsOperation: FetchCommitsOperationProtocol {
    
    public init(deviceInfo: DeviceInfo, shouldStartFromSyncedCommit: Bool = false, syncStorage: SyncStorage = SyncStorage.sharedInstance, connector: IPaymentDeviceConnector? = nil) {
        self.deviceInfo = deviceInfo
        self.startFromSyncedCommit = shouldStartFromSyncedCommit
        self.syncStorage = syncStorage
        self.connector = connector
    }
    
    public enum ErrorCode: Error {
        case parsingError
    }
    
    public func startWith(limit: Int, andOffset offset: Int) -> Observable<[Commit]> {
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
                    result.collectAllAvailable() { (results, error) in
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
    
    open func generateCommitIdFromWhichWeShouldStart() -> Observable<String> {
        var commitId = ""
        if self.startFromSyncedCommit {
            if let getDeviceLastCommitId = self.connector?.getDeviceLastCommitId, let _ = self.connector?.setDeviceLastCommitId {
                commitId = getDeviceLastCommitId()
            } else {
                commitId = self.syncStorage.getLastCommitId(self.deviceInfo.deviceIdentifier!)
            }
        }
        
        if commitId.isEmpty {
            return Observable.create({ [weak self] (observer) -> Disposable in
                self?.deviceInfo.lastAckCommit(completion: { (commit, error) in
                    if let error = error {
                        log.error("Can't get lastAckCommit. Error: \(error)")
                        // anyway continue sync process from beginning
                        observer.onNext("")
                    } else {
                        observer.onNext(commit?.commit ?? "")
                    }
                    
                    observer.onCompleted()
                })
                
                return Disposables.create()
            })
        } else {
            return Observable.just(commitId)
        }

    }
    
    
    public var deviceInfo: DeviceInfo!
    private var connector: IPaymentDeviceConnector?
    
    // private
    private let syncStorage: SyncStorage
    private let startFromSyncedCommit: Bool
    private let disposeBag = DisposeBag()
    
    //rx
    private let publisher = PublishSubject<[Commit]>()
}
