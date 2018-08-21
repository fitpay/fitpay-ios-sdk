/// Errors for A2AVerificationRequest
public enum A2AVerificationError: String {
    
    /// Created by the SDK if A2AVerificationRequest can't be parsed correctly
    case cantProcess = "cantProcessVerification"
    
    /// Sent by the bank in case of declined
    case declined = "appToAppDeclined"
    
    /// Sent by the bank in case of failure
    case failure = "appToAppFailure"
    
    /// Used for non-supported card types - currently Mastercard on iOS
    case notSupported = "appToAppNotSupported"
    
    /// Can be used by OEM app to let the webview know there was an answer, a pop-up will be shown
    case unknown = "unknown"
    
    /// Can be used by OEM app to let the webview know there was an answer, no pop-up will display
    case silentUnknown = "silentUnknown"
}
