import KeychainAccess

public class SyncStorage {
    public static let sharedInstance = SyncStorage()
    
    fileprivate var keychain: Keychain
    fileprivate let keychainFieldName: String = "FitPayLastSyncCommitId"
    fileprivate let keychainPackageFieldName: String = "FitPayLastPackageId"

    public internal(set) var lastPackageId: Int {
        get {
            
            return Int(self.keychain[keychainPackageFieldName] ?? "1") ?? 1
        }
        set {
            self.keychain[keychainPackageFieldName] = String(newValue)
        }
    }
    
    private init() {
        self.keychain = Keychain(service: "com.masterofcode-llc.FitpaySDK")
    }

    internal func getLastCommitId(_ deviceId:String) -> String {
        if let commitId = self.keychain[deviceId] {
            return commitId
        } else {
            return String()
        }
    }

    internal func setLastCommitId(_ deviceId:String, commitId:String) -> Void {
        self.keychain[deviceId] = commitId
    }
    
    
}
