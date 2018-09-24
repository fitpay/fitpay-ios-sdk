import Foundation

open class User: NSObject, ClientModel, Serializable, SecretApplyable {
    
    open var id: String?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var lastModified: String?
    open var lastModifiedEpoch: TimeInterval?
    
    open var listCreditCardsAvailable: Bool {
        return self.links?.url(User.creditCardsResourceKey) != nil
    }
    
    open var listDevicesAvailable: Bool {
        return self.links?.url(User.devicesResourceKey) != nil
    }
    
    var links: [ResourceLink]?
    var encryptedData: String?
    var info: UserInfo?

    weak var client: RestClient?
    
    private static let creditCardsResourceKey = "creditCards"
    private static let devicesResourceKey = "devices"
    private static let selfResourceKey = "self"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case id
        case created = "createdTs"
        case createdEpoch = "createdTsEpoch"
        case lastModified = "lastModifiedTs"
        case lastModifiedEpoch = "lastModifiedTsEpoch"
        case encryptedData
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        id = try? container.decode(.id)
        created = try? container.decode(.created)
        createdEpoch = try container.decode(.createdEpoch, transformer: NSTimeIntervalTypeTransform())
        lastModified = try? container.decode(.lastModified)
        lastModifiedEpoch = try container.decode(.lastModifiedEpoch, transformer: NSTimeIntervalTypeTransform())
        encryptedData = try? container.decode(.encryptedData)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(id, forKey: .id)
        try? container.encode(created, forKey: .created)
        try? container.encode(createdEpoch, forKey: .createdEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(lastModified, forKey: .lastModified)
        try? container.encode(lastModifiedEpoch, forKey: .lastModifiedEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(encryptedData, forKey: .encryptedData)
    }
    
    // MARK: - Public Functions
    
    /// Add a single credit card to a user's profile. If the card owner has no default card, then the new card will become the default.
    ///
    /// - Parameters:
    ///   - cardInfo: Credit Card Info including Address and IdVerification info
    ///   - deviceId: optional device which to add a credential to
    ///   - completion: CreateCreditCardHandler closure
    @objc public func createCreditCard(cardInfo: CardInfo, deviceId: String? = nil, completion: @escaping RestClient.CreditCardHandler) {
        let resource = User.creditCardsResourceKey
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client {
            client.createCreditCard(url, cardInfo: cardInfo, deviceId: deviceId, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: User.self, client: client, url: url, resource: resource))
        }
    }
    
    /**
     Retrieves the details of an existing credit card. You need only supply the unique identifier that was returned upon creation.
     
     - parameter excludeState: Exclude all credit cards in the specified state. If you desire to specify multiple excludeState values, then repeat this query parameter multiple times.
     - parameter limit:        max number of profiles per page
     - parameter offset:       start index position for list of entities returned
     - parameter completion:   CreditCardsHandler closure
     */
    public func getCreditCards(excludeState: [String], limit: Int, offset: Int, deviceId: String? = nil, completion: @escaping RestClient.CreditCardsHandler) {
        let resource = User.creditCardsResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.creditCards(url, excludeState: excludeState, limit: limit, offset: offset, deviceId: deviceId, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: User.self, client: client, url: url, resource: resource))
        }
    }
    
    /**
     For a single user, retrieve a pageable collection of devices in their profile
     
     - parameter limit:      max number of profiles per page
     - parameter offset:     start index position for list of entities returned
     - parameter completion: DevicesHandler closure
     */
    public func getDevices(limit: Int, offset: Int, completion: @escaping RestClient.DevicesHandler) {
        let resource = User.devicesResourceKey
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client {
            client.makeGetCall(url, limit: limit, offset: offset, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: User.self, client: client, url: url, resource: resource))
        }
    }
    
    /**
     For a single user, create a new device in their profile
     
     - parameter device: DeviceInfo
     */
    @objc public func createDevice(_ device: Device, completion: @escaping RestClient.DeviceHandler) {
        let resource = User.devicesResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.createNewDevice(url, deviceInfo: device, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: User.self, client: client, url: url, resource: resource))
        }
    }
    
    @objc public func deleteUser(_ completion: @escaping RestClient.DeleteHandler) {
        let resource = User.selfResourceKey
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client {
            client.makeDeleteCall(url, completion: completion)
        } else {
            completion(ErrorResponse.clientUrlError(domain: User.self, client: client, url: url, resource: resource))
        }
    }
    
    @objc public func updateUser(firstName: String?, lastName: String?, birthDate: String?, originAccountCreated: String?, termsAccepted: String?, termsVersion: String?, completion: @escaping RestClient.UserHandler) {
        let resource = User.selfResourceKey
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client {
            client.updateUser(url, firstName: firstName, lastName: lastName, birthDate: birthDate, originAccountCreated: originAccountCreated, termsAccepted: termsAccepted, termsVersion: termsVersion, completion: completion)
        } else {
            completion(nil, ErrorResponse.clientUrlError(domain: User.self, client: client, url: url, resource: resource))
        }
    }
    
    // MARK: - Internal Helpers
    
    func applySecret(_ secret: Data, expectedKeyId: String?) {
        self.info = JWE.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
    }
    
}
