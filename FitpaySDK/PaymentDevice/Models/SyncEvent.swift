import Foundation

struct SyncEvent {
    var event: SyncEventType
    var data: [String: Any]
}

@objc public enum SyncEventType: Int, FitpayEventTypeProtocol {
    case connectingToDevice = 0x1
    case connectingToDeviceFailed
    case connectingToDeviceCompleted
    
    case syncStarted
    case syncFailed
    case syncCompleted
    case syncProgress
    case receivedCardsWithTowApduCommands
    case apduCommandsProgress
    
    case apduPackageComplete
    
    case commitsReceived
    case commitProcessed
    
    case cardAdded
    case cardDeleted
    case cardActivated
    case cardDeactivated
    case cardReactivated
    case setDefaultCard
    case resetDefaultCard
    case cardProvisionFailed
    case cardMetadataUpdated
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .connectingToDevice:
            return "Connecting to device"
        case .connectingToDeviceFailed:
            return "Connecting to device failed"
        case .connectingToDeviceCompleted:
            return "Connecting to device completed"
        case .syncStarted:
            return "Sync started"
        case .syncFailed:
            return "Sync failed"
        case .syncCompleted:
            return "Sync completed"
        case .syncProgress:
            return "Sync progress"
        case .receivedCardsWithTowApduCommands:
            return "Received cards with Top of Wallet APDU commands"
        case .apduCommandsProgress:
            return "APDU progress"
        case .commitsReceived:
            return "Commits received"
        case .commitProcessed:
            return "Processed commit"
        case .apduPackageComplete:
            return "Processing APDU package complete"
        case .cardAdded:
            return "New card was added"
        case .cardDeleted:
            return "Card was deleted"
        case .cardActivated:
            return "Card was activated"
        case .cardDeactivated:
            return "Card was deactivated"
        case .cardReactivated:
            return "Card was reactivated"
        case .setDefaultCard:
            return "New default card was manually set"
        case .resetDefaultCard:
            return "New default card was automatically set"
        case .cardProvisionFailed:
            return "Card provision failed event."
        case .cardMetadataUpdated:
            return "Card metadata updated event."
        }
    }

}
