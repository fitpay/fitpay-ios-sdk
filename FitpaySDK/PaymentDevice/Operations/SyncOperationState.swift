import Foundation

enum SyncOperationState {
    case waiting
    case started
    case connecting
    case connected
    case commitsReceived(commits: [Commit])
    case completed(Error?)
}
