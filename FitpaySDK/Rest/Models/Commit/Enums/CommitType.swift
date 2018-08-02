import Foundation

public enum CommitType: String {
    case creditCardCreated          = "CREDITCARD_CREATED"
    case creditCardDeactivated      = "CREDITCARD_DEACTIVATED"
    case creditCardActivated        = "CREDITCARD_ACTIVATED"
    case creditCardReactivated      = "CREDITCARD_REACTIVATED"
    case creditCardDeleted          = "CREDITCARD_DELETED"
    case resetDefaultCreditCard     = "RESET_DEFAULT_CREDITCARD"
    case setDefaultCreditCard       = "SET_DEFAULT_CREDITCARD"
    case apduPackage                = "APDU_PACKAGE"
    case creditCardProvisionFailed  = "CREDITCARD_PROVISION_FAILED"
    case creditCardProvisionSuccess = "CREDITCARD_PROVISION_SUCCESS"
    case creditCardMetaDataUpdated  = "CREDITCARD_METADATA_UPDATED"
    case unknown                    = "UNKNOWN"
}
