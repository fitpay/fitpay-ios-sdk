import Foundation

public enum NotificationsEventType: Int, FitpayEventTypeProtocol {
    case receivedSyncNotification = 0x1
    case receivedSimpleNotification
    
    /**
     *  AllNotificationsProcessed event called when processing of notification finished e.g.
     *  sync with payment device ect...
     *  If processing was done in background, than in completion for this event you should call
     *  fetchCompletionHandler from
     *  application(_:didReceiveRemoteNotification:fetchCompletionHandler:).
     */
    case allNotificationsProcessed
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .receivedSyncNotification:
            return "Received notification with sync operation"
        case .receivedSimpleNotification:
            return "Received simple notification without sync operation"
        case .allNotificationsProcessed:
            return "All notification processed"
        }
    }
    
}
