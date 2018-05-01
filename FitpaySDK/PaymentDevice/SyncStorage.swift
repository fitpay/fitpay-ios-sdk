import Foundation

public protocol SyncStorageProtocol {
    func getLastCommitId(_ deviceId: String) -> String
    func setLastCommitId(_ deviceId: String, commitId: String) -> Void
}

public class SyncStorage: SyncStorageProtocol { //TODO: convert to setter/getter variable
    public static let sharedInstance = SyncStorage()
    
    private var defaults = UserDefaults.standard

    public func getLastCommitId(_ deviceId: String) -> String {
       return defaults.string(forKey: deviceId) ?? ""
    }

    public func setLastCommitId(_ deviceId: String, commitId: String) -> Void {
        defaults.set(commitId, forKey: deviceId)
    }
}
