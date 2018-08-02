import Foundation

protocol SyncStorageProtocol {
    func getLastCommitId(_ deviceId: String) -> String
    func setLastCommitId(_ deviceId: String, commitId: String) -> Void
}

class SyncStorage: SyncStorageProtocol { //TODO: convert to setter/getter variable
    static let sharedInstance = SyncStorage()
    
    private var defaults = UserDefaults.standard

    func getLastCommitId(_ deviceId: String) -> String {
       return defaults.string(forKey: deviceId) ?? ""
    }

    func setLastCommitId(_ deviceId: String, commitId: String) -> Void {
        defaults.set(commitId, forKey: deviceId)
    }
}
