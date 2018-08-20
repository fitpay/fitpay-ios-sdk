// Errors for A2AVerificationRequest
public enum A2AVerificationError: String {
    case cantProcess    = "cantProcessVerification"
    case declined       = "appToAppDeclined"
    case failure        = "appToAppFailure"
    case notSupported   = "appToAppNotSupported"
    case unknown        = "unknown"
    case silentUnknown  = "silentUnknown"
}
