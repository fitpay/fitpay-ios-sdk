import Foundation

public enum VerificationResult: String, Serializable {
    case success                        = "SUCCESS"
    case incorrectCode                  = "INCORRECT_CODE"
    case incorrectCodeRetriesExceeded   = "INCORRECT_CODE_RETRIES_EXCEEDED"
    case expiredCode                    = "EXPIRED_CODE"
    case incorrectTAV                   = "INCORRECT_TAV"
    case expiredSession                 = "EXPIRED_SESSION"
}
