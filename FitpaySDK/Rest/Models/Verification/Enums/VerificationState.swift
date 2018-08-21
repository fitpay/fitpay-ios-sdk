import Foundation

/// Current state of `VerificationMethod`
public enum VerificationState: String, Serializable {
    
    /// Supported by issuer and valid, display if app supports it
    case availableForSelection = "AVAILABLE_FOR_SELECTION"
    
    /// User previously selected method. Waiting for user to take additional action (enter otp, call issuer, etc.)
    case awaitingVerification = "AWAITING_VERIFICATION"
    
    /// OTP code that was requested has expired.
    case expired = "EXPIRED"
    
    /// This is the verification method the user successfully used.
    /// This may be removed in the future as we don't return verificationMethods unless card is in pending user verification.
    case verified = "VERIFIED"
    
    /// Verification was valid at some point in the card's lifecycle but no longer valid (ie: user submitted wrong code too many times).
    /// Don't display.
    case error = "ERROR"   
}
