import Foundation

public enum VerificationState: String, Serializable {
    case availableForSelection  = "AVAILABLE_FOR_SELECTION"
    case awaitingVerification   = "AWAITING_VERIFICATION"
    case expired                = "EXPIRED"
    case verified               = "VERIFIED"
}
