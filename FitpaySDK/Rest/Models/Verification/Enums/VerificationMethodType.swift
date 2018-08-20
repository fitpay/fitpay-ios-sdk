import Foundation

/// Verification method types for `VerificationMethod`
///
/// [User Verification Documentation]: https://docs.fit-pay.com/creditCards/userVerification/#
public enum VerificationMethodType: String, Serializable {
    
    /// Issuer sends one time passcode (OTP) to card holder via text message to a phone number on file with issuer
    case textToCardholderNumber = "TEXT_TO_CARDHOLDER_NUMBER"
    
    /// Issuer Sends OTP to card holder via email to an email on file with issuer
    case emailToCardholderAddress = "EMAIL_TO_CARDHOLDER_ADDRESS"
    
    /// Card holder calls issuing bank's customer support to activate through an automated system
    case cardholderToCallAutomatedNumber = "CARDHOLDER_TO_CALL_AUTOMATED_NUMBER"
    
    /// Card holder calls issuing bank's customer support to activate through a live agent
    case cardholderToCallMannedNumber = "CARDHOLDER_TO_CALL_MANNED_NUMBER"
    
    /// Card holder logs into issuer's website
    case cardholderToVisitWebsite = "CARDHOLDER_TO_VISIT_WEBSITE"
    
    /// Card holder calls issuing bank's customer support to get OTP
    case cardholderToCallForAutomatedOTPCode = "CARDHOLDER_TO_CALL_FOR_AUTOMATED_OTP_CODE"
    
    /// Issuer's customer service calls card holder to activate
    case agentToCallCardholderNumber = "AGENT_TO_CALL_CARDHOLDER_NUMBER"
    
    /// Issuer's customer service calls card holder to activate
    case issuerToCallCardholderNumber = "ISSUER_TO_CALL_CARDHOLDER_NUMBER"
    
    /// Card holder authenticates with issuer's mobile app
    case cardholderToUseMobileApp = "CARDHOLDER_TO_USE_MOBILE_APP"

}
