import Foundation

/// used as a variable in `RTMDelegate.willDisplayStatusMessage`
@objc public enum WVDeviceStatus: Int {
    
    /// Device is disconnected
    case disconnected
    
    /// Pairing with device
    case pairing
    
    /// Checking for wallet updates
    case syncGettingUpdates
    
    /// No pending updates for device
    case syncNoUpdates
    
    /// Connecting to device
    case syncUpdatingConnectingToDevice
    
    /// Updates available for wallet, but unable to connect to device
    case syncUpdatingConnectionFailed
    
    /// Syncing updates to device
    case syncUpdating
    
    /// Sync complete, device up to date
    case syncComplete
    
    /// Sync error
    case syncError
    
    func statusMessageType() -> WvConfig.WVMessageType {
        switch self {
        case .disconnected:
            return .pending
        case .syncGettingUpdates,
             .syncNoUpdates,
             .syncUpdatingConnectionFailed,
             .syncComplete:
            return .success
        case .pairing,
             .syncUpdating,
             .syncUpdatingConnectingToDevice:
            return .progress
        case .syncError:
            return .error
        }
    }
    
    func defaultMessage() -> String {
        switch self {
        case .disconnected:
            return "Device is disconnected"
        case .syncGettingUpdates:
            return "Checking for wallet updates..."
        case .syncNoUpdates:
            return "No pending updates for device"
        case .pairing:
            return "Pairing with device..."
        case .syncUpdatingConnectingToDevice:
            return "Connecting to device..."
        case .syncUpdatingConnectionFailed:
            return "Updates available for wallet - unable to connect to device - check connection"
        case .syncUpdating:
            return "Syncing updates to device..."
        case .syncComplete:
            return "Sync complete - device up to date - no updates available"
        case .syncError:
            return "Sync error"
        }
    }
    
}
