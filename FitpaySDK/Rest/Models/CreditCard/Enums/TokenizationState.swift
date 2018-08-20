import Foundation

public enum TokenizationState: String, Codable {
    case new                        = "NEW"
    case notEligible                = "NOT_ELIGIBLE"
    case eligible                   = "ELIGIBLE"
    case declinedTermsAndConditions = "DECLINED_TERMS_AND_CONDITIONS"
    case pendingActive              = "PENDING_ACTIVE"
    case pendingVerification        = "PENDING_VERIFICATION"
    case deleted                    = "DELETED"
    case active                     = "ACTIVE"
    case deactivated                = "DEACTIVATED"
    case error                      = "ERROR"
    case declined                   = "DECLINED"
}
