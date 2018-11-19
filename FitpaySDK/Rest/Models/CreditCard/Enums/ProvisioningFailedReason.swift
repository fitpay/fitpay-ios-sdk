import Foundation

/// Reason a provisioning attempt failed
///
/// - paymentNetworkRejection: the provision request was declined
/// - noSecurityDomainAvailable: card network didn't have all of the information it needed to provision. might be because device didn't sync.
/// - failedCredentialPersonalization: the perso wasn't processed in time or resulted in an error
/// - sdCreateException: unexpected error, similar to a 400 http response
/// - provisioningLimitReached: max number of credentials for the pan has been reached
/// - userDeclinedTerms: user declined the issuer's terms and conditions document
/// - failedRetrievingKeys: unexpected error, similar to a 400 http response
/// - invalidDigitizationDecision: card network didn't provide a valid decision on the request
/// - missingActivationMethods: provisioning request was approved with additional verification but no verification methods were provided
/// - tokenStatusCompletionTimeout: card network didn't respond to the provision request
/// - tokenStatusError: card network responded with an error during the provisioning process
/// - unkown: unknown
public enum ProvisioningFailedReason: String, Codable {
    case paymentNetworkRejection            = "PAYMENT_NETWORK_REJECTION"
    case noSecurityDomainAvailable          = "NO_SECURITY_DOMAIN_AVAILABLE"
    case failedCredentialPersonalization    = "FAILED_CREDENTIAL_PERSONALIZATION"
    case sdCreateException                  = "SD_CREATE_EXCEPTION"
    case provisioningLimitReached           = "PROVISIONING_LIMIT_REACHED"
    case userDeclinedTerms                  = "USER_DECLINED_TERMS"
    case failedRetrievingKeys               = "FAILED_RETRIEVING_KEYS"
    case invalidDigitizationDecision        = "INVALID_DIGITIZATION_DECISION"
    case missingActivationMethods           = "MISSING_ACTIVATION_METHODS"
    case tokenStatusCompletionTimeout       = "TOKEN_STATUS_COMPLETION_TIMEOUT"
    case tokenStatusError                   = "TOKEN_STATUS_ERROR"
    case unkown                             = "UNKNOWN"
}
