import Foundation

public enum VerificationMethodType: String, Serializable {
    case textToCardholderNumber             = "TEXT_TO_CARDHOLDER_NUMBER"
    case emailToCardholderAddress           = "EMAIL_TO_CARDHOLDER_ADDRESS"
    case cardholderToCallAutomatedNumber    = "CARDHOLDER_TO_CALL_AUTOMATED_NUMBER"
    case cardholderToCallMannedNumber       = "CARDHOLDER_TO_CALL_MANNED_NUMBER"
    case cardholderToVisitWebsite           = "CARDHOLDER_TO_VISIT_WEBSITE"
    case cardholderToUserMobileApp          = "CARDHOLDER_TO_USE_MOBILE_APP"
    case issuerToCallCardholderNumber       = "ISSUER_TO_CALL_CARDHOLDER_NUMBER"
}
