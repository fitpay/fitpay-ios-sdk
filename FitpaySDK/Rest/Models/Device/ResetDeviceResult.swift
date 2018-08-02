import Foundation

@objcMembers open class ResetDeviceResult: Serializable {
    
    open var resetId: String?
    open var status: DeviceResetStatus?
    open var seStatus: DeviceResetStatus?

    open var deviceResetUrl: String? {
        return self.links?.url(ResetDeviceResult.selfResourceKey)
    }
    
    var links: [ResourceLink]?

    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case resetId
        case status
        case seStatus
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        resetId = try? container.decode(.resetId)
        status = try? container.decode(.status)
        seStatus = try? container.decode(.seStatus)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(resetId, forKey: .resetId)
        try? container.encode(status, forKey: .status)
        try? container.encode(seStatus, forKey: .seStatus)
    }
}
