import KeychainAccess

internal class SyncStorage {
    private var keychain : Keychain
    private let keychainFieldName : String = "FitPayLastSyncCommitId"

    init() {
        self.keychain = Keychain(service: "com.masterofcode-llc.FitpaySDK")
    }

    internal func getLastCommitId(deviceId:String) -> String {
        if let commitId = self.keychain[deviceId] {
            return commitId
        } else {
            return String()
        }
    }

    internal func setLastCommitId(deviceId:String, commitId:String) -> Void {
        self.keychain[deviceId] = commitId
    }
}