import Foundation

public enum APDUPackageResponseState: String, Serializable {
    case processed    = "PROCESSED"
    case failed       = "FAILED"
    case error        = "ERROR"
    case expired      = "EXPIRED"
    case notProcessed = "NOT_PROCESSED"
}
