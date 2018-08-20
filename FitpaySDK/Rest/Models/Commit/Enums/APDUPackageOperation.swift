import Foundation

public enum APDUPackageOperation: String, Serializable {
    case boarding        = "BOARDING"
    case sdCreate        = "SD_CREATE"
    case sdDelete        = "SD_DELETE"
    case appletInstall   = "APPLET_INSTALL"
    case appletDelete    = "APPLET_DELETE"
    case sdPerso         = "SD_PERSO"
    case passthrough     = "PASSTHROUGH"
}
