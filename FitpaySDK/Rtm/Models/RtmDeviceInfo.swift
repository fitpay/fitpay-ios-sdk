public class RtmDeviceInfo: DeviceInfo {

    public init(deviceInfo: DeviceInfo) {
        super.init()
        copyFieldsFrom(deviceInfo: deviceInfo)
    }

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case deviceIdentifier
        case deviceName
        case deviceType
        case manufacturerName
        case serialNumber
        case modelNumber
        case hardwareRevision
        case firmwareRevision
        case softwareRevision
        case notificationToken
        case osName
        case systemId
        case licenseKey
        case bdAddress
        case pairing
        case cardRelationships
        case metadata
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }

    func copyFieldsFrom(deviceInfo: DeviceInfo) {
        self.links             = deviceInfo.links
        self.deviceIdentifier  = deviceInfo.deviceIdentifier
        self.deviceName        = deviceInfo.deviceName
        self.deviceType        = deviceInfo.deviceType
        self.manufacturerName  = deviceInfo.manufacturerName
        self.state             = deviceInfo.state
        self.serialNumber      = deviceInfo.serialNumber
        self.modelNumber       = deviceInfo.modelNumber
        self.hardwareRevision  = deviceInfo.hardwareRevision
        self.firmwareRevision  = deviceInfo.firmwareRevision
        self.softwareRevision  = deviceInfo.softwareRevision
        self.notificationToken = deviceInfo.notificationToken
        self.createdEpoch      = deviceInfo.createdEpoch
        self.created           = deviceInfo.created
        self.osName            = deviceInfo.osName
        self.systemId          = deviceInfo.systemId
        self.licenseKey        = deviceInfo.licenseKey
        self.bdAddress         = deviceInfo.bdAddress
        self.pairing           = deviceInfo.pairing
        self.cardRelationships = deviceInfo.cardRelationships
        self.metadata          = deviceInfo.metadata
        self.secureElementId   = deviceInfo.secureElementId
        self.casd              = deviceInfo.casd
    }

}
