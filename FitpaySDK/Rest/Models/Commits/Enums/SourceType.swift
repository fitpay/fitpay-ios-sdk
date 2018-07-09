import Foundation

public enum SourceType: String, Serializable {
    case deviceApi = "device"
    case tsmGatewayApi = "tsm"
    case gAndDIntegrationApi = "gi_de"
    case mdesGatewayApi = "mdes"
    case discoverGatewayApi = "discover"
    case vdepGatewayApi = "vdep"
}
