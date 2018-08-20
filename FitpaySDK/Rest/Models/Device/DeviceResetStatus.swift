import Foundation

public enum DeviceResetStatus: String, Serializable {
    case InProgress     = "IN_PROGRESS"
    case ResetComplete  = "RESET_COMPLETE"
    case Deleted        = "DELETED"
    case DeleteFailed   = "DELETE_FAILED"
    case ResetFailed    = "RESET_FAILED"
}
