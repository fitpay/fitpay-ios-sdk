import Foundation

public enum APDUPackageCategory: String, Serializable {
    case platform    = "PLATFORM"
    case dsems       = "DSEMS"
    case ls          = "LS"
    case seiTsm      = "SEI_TSM"
    case spTsm       = "SP_TSM"
}
