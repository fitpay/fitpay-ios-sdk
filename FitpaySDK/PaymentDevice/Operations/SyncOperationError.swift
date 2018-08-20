import Foundation

enum SyncOperationError: Error {
    case deviceIdentifierIsNil
    case couldNotConnectToDevice
    case paymentDeviceDisconnected
    case cantFetchCommits
    case alreadySyncing
    case unk
}
