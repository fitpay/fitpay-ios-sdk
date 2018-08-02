import Foundation

public enum SyncInitiator: String, Serializable {
    case platform       = "PLATFORM"
    case notification   = "NOTIFICATION"
    case webHook        = "WEB_HOOK"
    case eventStream    = "EVENT_STREAM"
    case notDefined     = "NOT DEFINED"
}
