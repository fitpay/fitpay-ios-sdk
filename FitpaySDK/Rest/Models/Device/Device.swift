import Foundation

@objcMembers open class Device: NSObject, ClientModel, Serializable {

    /// Unique identifier to platform asset that contains details about the embedded secure element for the device.
    open var profileId: String?

    //TODO: put back to non-computed variable when making set private
    private var _deviceIdentifier: String?
    
    /// Unique identifier for a single device generated by the platofrm.
    open var deviceIdentifier: String? {
        get {
            return _deviceIdentifier
        }
        @available(*, deprecated, message: "as of v1.0.2")
        set(newValue) {
            _deviceIdentifier = newValue
        }
    }
   
    /// The name of the device model
    open var deviceName: String?
    
    /// Type of Device
    ///
    /// Options include: `ACTIVITY_TRACKER`, `MOCK`, `PHONE` (host device only), `SMART_STRAP`, `TABLET` (host device only), `WATCH`
    open var deviceType: String?
    
    /// The manufacturer name of the device
    open var manufacturerName: String?
    
    open var state: String?
    
    /// The serial number for a particular instance of the device
    open var serialNumber: String?
    
    /// The model number that is assigned by the device vendor
    open var modelNumber: String?
    
    /// The hardware revision for the hardware within the device
    open var hardwareRevision: String?
    
    /// The firmware revision for the firmware within the device. Value may be normalized to meet payment network specifications.
    open var firmwareRevision: String?
    
    open var softwareRevision: String?
    
    open var notificationToken: String?
    
    open var createdEpoch: TimeInterval?
    
    open var created: String?
    
    /// The code name of the firmware operating system on the device
    open var osName: String?
    
    /// A structure containing an Organizationally Unique Identifier (OUI) followed
    /// by a manufacturer-defined identifier and is unique for each individual instance of the product
    open var systemId: String?
    
    open var licenseKey: String?
    
    /// MAC address for Bluetooth
    open var bdAddress: String?
    
    open var pairing: String?

    /// Representation of a Secure Element
    open var secureElement: SecureElement?
    
    /// Will be present if makeDefault is called on a Credit Card with this deviceId
    open var defaultCreditCardId: String?
    
    /// Extra metadata specific for a particular type of device
    open var metadata: [String: Any]?

    /// returns true if user link is returned on the model and available to call
    open var userAvailable: Bool {
        return links?[Device.userResourceKey] != nil
    }

    /// returns true if commits link is returned on the model and available to call
    open var listCommitsAvailable: Bool {
        return links?[Device.commitsResourceKey] != nil
    }
    
    /// returns true if lastAckCommit link is returned on the model and available to call
    open var lastAckCommitAvailable: Bool {
        return links?[Device.lastAckCommitResourceKey] != nil
    }
    
    /// returns true if defaultCreditCard link is returned on the model and available to call
    open var defaultCreditCardAvailable: Bool {
        return links?[Device.defaultCreditCardKey] != nil
    }

    /// returns the device reset URL if deviceResetTasksKey link is returned on the model and available to call
    @available(*, deprecated, message: "as of v1.2.1 - a reset method will be added in the future")
    open var deviceResetUrl: String? {
        return links?[Device.deviceResetTasksKey]?.href
    }
    
    var links: [String: Link]?
    weak var client: RestClient?

    typealias NotificationTokenUpdateCompletion = (_ changed: Bool, _ error: ErrorResponse?) -> Void
    
    private static let userResourceKey = "user"
    private static let commitsResourceKey = "commits"
    private static let selfResourceKey = "self"
    private static let lastAckCommitResourceKey = "lastAckCommit"
    private static let deviceResetTasksKey = "deviceResetTasks"
    private static let defaultCreditCardKey = "defaultCreditCard"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case deviceIdentifier
        case deviceName
        case deviceType
        case manufacturerName
        case state
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
        case secureElement
        case metadata
        case profileId
        case defaultCreditCardId
    }

    // MARK: - Lifecycle
    
    override public init() {
        super.init()
    }

    init(profileId: String? = nil, deviceType: String, manufacturerName: String, deviceName: String, serialNumber: String?, modelNumber: String?, hardwareRevision: String?, firmwareRevision: String?, softwareRevision: String?, notificationToken: String?, systemId: String?, osName: String?, secureElement: SecureElement?) {
        self.profileId = profileId
        self.deviceType = deviceType
        self.manufacturerName = manufacturerName
        self.deviceName = deviceName
        self.serialNumber = serialNumber
        self.modelNumber = modelNumber
        self.hardwareRevision = hardwareRevision
        self.firmwareRevision = firmwareRevision
        self.softwareRevision = softwareRevision
        self.notificationToken = notificationToken
        self.systemId = systemId
        self.osName = osName
        self.secureElement = secureElement
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try? container.decode(.links)
        created = try? container.decode(.created)
        createdEpoch = try container.decode(.createdEpoch, transformer: NSTimeIntervalTypeTransform())
        _deviceIdentifier = try? container.decode(.deviceIdentifier)
        deviceName = try? container.decode(.deviceName)
        deviceType = try? container.decode(.deviceType)
        manufacturerName = try? container.decode(.manufacturerName)
        state = try? container.decode(.state)
        serialNumber = try? container.decode(.serialNumber)
        modelNumber = try? container.decode(.modelNumber)
        hardwareRevision = try? container.decode(.hardwareRevision)
        firmwareRevision =  try? container.decode(.firmwareRevision)
        softwareRevision = try? container.decode(.softwareRevision)
        notificationToken = try? container.decode(.notificationToken)
        osName = try? container.decode(.osName)
        systemId = try? container.decode(.systemId)
        licenseKey = try? container.decode(.licenseKey)
        bdAddress = try? container.decode(.bdAddress)
        pairing = try? container.decode(.pairing)
        secureElement = try? container.decode(.secureElement)
        metadata = try? container.decode([String: Any].self)
        profileId = try? container.decode(.profileId)
        defaultCreditCardId = try? container.decode(.defaultCreditCardId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encodeIfPresent(links, forKey: .links)
        try? container.encode(created, forKey: .created)
        try container.encode(createdEpoch, forKey: .createdEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(deviceIdentifier, forKey: .deviceIdentifier)
        try? container.encode(deviceName, forKey: .deviceName)
        try? container.encode(deviceType, forKey: .deviceType)
        try? container.encode(manufacturerName, forKey: .manufacturerName)
        try? container.encode(state, forKey: .state)
        try? container.encode(serialNumber, forKey: .serialNumber)
        try? container.encode(modelNumber, forKey: .modelNumber)
        try? container.encode(hardwareRevision, forKey: .hardwareRevision)
        try? container.encode(firmwareRevision, forKey: .firmwareRevision)
        try? container.encode(softwareRevision, forKey: .softwareRevision)
        try? container.encode(notificationToken, forKey: .notificationToken)
        try? container.encode(osName, forKey: .osName)
        try? container.encode(systemId, forKey: .systemId)
        try? container.encode(licenseKey, forKey: .licenseKey)
        try? container.encode(bdAddress, forKey: .bdAddress)
        try? container.encode(pairing, forKey: .pairing)
        try? container.encode(secureElement, forKey: .secureElement)
        try? container.encodeIfPresent(metadata, forKey: .metadata)
        try? container.encode(profileId, forKey: .profileId)
        try? container.encode(defaultCreditCardId, forKey: .defaultCreditCardId)
    }
    
    // MARK: - Public Functions
    
    /**
     Delete a single device
     
     - parameter completion: DeleteDeviceHandler closure
     */
    @objc open func deleteDeviceInfo(_ completion: @escaping RestClient.DeleteHandler) {
        let resource = Device.selfResourceKey
       
        guard let url = links?[resource]?.href, let client = client else {
            completion(composeError(resource))
            return
        }
        
        client.makeDeleteCall(url, completion: completion)
    }

    /**
     Update the details of an existing device
     (For optional parameters use nil if field doesn't need to be updated)

     - parameter firmwareRevision?: firmware revision
     - parameter softwareRevision?: software revision
     - parameter softwareRevision?: notification token
     - parameter completion:        UpdateDeviceHandler closure
     */
    @available(*, deprecated, message: "as of v1.2")
    @objc open func update(_ firmwareRevision: String? = nil, softwareRevision: String? = nil, notifcationToken: String? = nil, completion: @escaping RestClient.DeviceHandler) {
        let resource = Device.selfResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.updateDevice(url, firmwareRevision: firmwareRevision, softwareRevision: softwareRevision, notificationToken: notifcationToken, completion: completion)
    }
    
    /**
     Update the details of an existing device use nil if field doesn't need to be updated
     Cannot remove values with this function
     Currently only supports firmwareRevision, softwareRevision and notificationToken but will support more properties in the future
     
     - parameter device: updated device
     */
    @objc open func updateDevice(_ device: Device, completion: @escaping RestClient.DeviceHandler) {
        let resource = Device.selfResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.updateDevice(url, device: device, completion: completion)
    }

    /**
     Retrieves a collection of all events that should be committed to this device
     
     - parameter commitsAfter: the last commit successfully applied. Query will return all subsequent commits which need to be applied.
     - parameter limit:        max number of profiles per page
     - parameter offset:       start index position for list of entities returned
     - parameter completion:   CommitsHandler closure
     */
    open func listCommits(commitsAfter: String?, limit: Int, offset: Int, completion: @escaping RestClient.CommitsHandler) {
        let resource = Device.commitsResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.commits(url, commitsAfter: commitsAfter, limit: limit, offset: offset, completion: completion)
    }
    
    /// Gets the default CreditCard for this device
    /// Corresponds to the card with defaultCreditCardId
    /// Can be set by calling makeDefault on a credit card
    ///
    /// - Parameter completion: Credit Card or Error
    open func getDefaultCreditCard(completion: @escaping RestClient.CreditCardHandler) {
        let resource = Device.defaultCreditCardKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.getDefaultCreditCard(url, completion: completion)
    }
    
    /**
     Retrieves last acknowledge commit for device
     
     - parameter completion: CommitHandler closure
     */
    open func lastAckCommit(completion: @escaping RestClient.CommitHandler) {
        let resource = Device.lastAckCommitResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }

    @objc open func user(_ completion: @escaping RestClient.UserHandler) {
        let resource = Device.userResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }

    // MARK: - Internal Functions
    
    func addNotificationToken(_ token: String, completion: @escaping RestClient.DeviceHandler) {
        let resource = Device.selfResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.addDeviceProperty(url, propertyPath: "/notificationToken", propertyValue: token, completion: completion)
    }
    
    func updateNotificationTokenIfNeeded(completion: NotificationTokenUpdateCompletion? = nil) {
        let newNotificationToken = FitpayNotificationsManager.sharedInstance.notificationToken
        
        guard !newNotificationToken.isEmpty && newNotificationToken != notificationToken else {
            completion?(false, nil)
            return
        }
        
        addNotificationToken(newNotificationToken) { [weak self] (device, error) in
            if error == nil && device != nil {
                log.debug("NOTIFICATIONS_DATA: NotificationToken updated to - \(device?.notificationToken ?? "null token")")
                self?.notificationToken = device?.notificationToken
                completion?(true, nil)
            } else {
                log.error("NOTIFICATIONS_DATA: can't update notification token for device, error: \(String(describing: error))")
                completion?(false, error)
            }
        }
    }
    
    // MARK: - Private Functions
    
    func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: Device.self, client: client, url: links?[resource]?.href, resource: resource)
    }
    
}
