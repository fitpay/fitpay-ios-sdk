
import ObjectMapper

open class DeviceInfo : NSObject, ClientModel, Mappable, SecretApplyable
{
    internal var links:[ResourceLink]?
    open var deviceIdentifier:String?
    open var deviceName:String?
    open var deviceType:String?
    open var manufacturerName:String?
    open var serialNumber:String?
    open var modelNumber:String?
    open var hardwareRevision:String?
    open var firmwareRevision:String?
    open var softwareRevision:String?
    open var notificationToken:String?
    open var createdEpoch:TimeInterval?
    open var created:String?
    open var osName:String?
    open var systemId:String?
    open var cardRelationships:[CardRelationship]?
    open var licenseKey:String?
    open var bdAddress:String?
    open var pairing:String?
    open var secureElementId:String?
    open var casd:String?
    fileprivate static let userResource = "user"
    fileprivate static let commitsResource = "commits"
    fileprivate static let selfResource = "self"
    
    fileprivate weak var _client:RestClient?

    // Extra metadata specific for a particural type of device
    open var metadata:[String : AnyObject]?
    
    open var userAvailable:Bool
    {
        return self.links?.url(DeviceInfo.userResource) != nil
    }
    
    open var listCommitsAvailable:Bool
    {
        return self.links?.url(DeviceInfo.commitsResource) != nil
    }
    
    internal var client:RestClient?
    {
        get
        {
            return self._client
        }
        set
        {
            self._client = newValue
            
            if let cardRelationships = self.cardRelationships
            {
                for cardRelationship in cardRelationships
                {
                    cardRelationship.client = self.client
                }
            }
        }
    }
    
    override public init() {
        
    }
    
    public required init?(map: Map)
    {
        
    }
    
    open func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        created <- map["createdTs"]
        createdEpoch <- (map["createdTsEpoch"], NSTimeIntervalTransform())
        deviceIdentifier <- map["deviceIdentifier"]
        deviceName <- map["deviceName"]
        deviceType <- map["deviceType"]
        manufacturerName <- map["manufacturerName"]
        serialNumber <- map["serialNumber"]
        modelNumber <- map["modelNumber"]
        hardwareRevision <- map["hardwareRevision"]
        firmwareRevision <- map["firmwareRevision"]
        softwareRevision <- map["softwareRevision"]
        notificationToken <- map["notificationToken"]
        osName <- map["osName"]
        systemId <- map["systemId"]
        licenseKey <- map["licenseKey"]
        bdAddress <- map["bdAddress"]
        pairing <- map["pairing"]
        casd <- map["casd"]
        if let secureElement = map["secureElement"].currentValue as? [String:String] {
            secureElementId = secureElement["secureElementId"]
        }  else {
            secureElementId <- map["secureElementId"]
        }
        
        if let cardRelationships = map["cardRelationships"].currentValue as? [AnyObject] {
            if cardRelationships.count > 0 {
                self.cardRelationships = [CardRelationship]()
                
                for itrObj in cardRelationships {
                    if let parsedObj = Mapper<CardRelationship>().map(JSON: itrObj as! [String : Any]) {
                        self.cardRelationships!.append(parsedObj)
                    }
                }
            }
        }
        
        metadata = map.JSON as [String : AnyObject]?
    }
    
    func applySecret(_ secret:Data, expectedKeyId:String?) {
        if let cardRelationships = self.cardRelationships {
            for modelObject in cardRelationships {
                modelObject.applySecret(secret, expectedKeyId: expectedKeyId)
            }
        }
    }
    
    var shortRTMRepersentation:String? {
        
        var dic : [String:Any] = [:]
        
        if let deviceType = self.deviceType {
            dic["deviceType"] = deviceType as AnyObject?
        }
        
        if let deviceName = self.deviceName {
            dic["deviceName"] = deviceName as AnyObject?
        }
        
        if let manufacturerName = self.manufacturerName {
            dic["manufacturerName"] = manufacturerName as AnyObject?
        }
        
        if let modelNumber = self.modelNumber {
            dic["modelNumber"] = modelNumber as AnyObject?
        }
        
        if let hardwareRevision = self.hardwareRevision {
            dic["hardwareRevision"] = hardwareRevision as AnyObject?
        }
        
        if let firmwareRevision = self.firmwareRevision {
            dic["firmwareRevision"] = firmwareRevision as AnyObject?
        }
        
        if let softwareRevision = self.softwareRevision {
            dic["softwareRevision"] = softwareRevision as AnyObject?
        }
        
        if let systemId = self.systemId {
            dic["systemId"] = systemId as AnyObject?
        }
        
        if let osName = self.osName {
            dic["osName"] = osName as AnyObject?
        }
        
        if let licenseKey = self.licenseKey {
            dic["licenseKey"] = licenseKey as AnyObject?
        }
        
        if let bdAddress = self.bdAddress {
            dic["bdAddress"] = bdAddress as AnyObject?
        }
        
        if let secureElementId = self.secureElementId {
            dic["secureElement"] = ["secureElementId" : secureElementId]
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: JSONSerialization.WritingOptions(rawValue: 0)) else {
            return nil
        }
        
        return String(data: jsonData, encoding: String.Encoding.utf8)
    }
    
    /**
     Delete a single device
     
     - parameter completion: DeleteDeviceHandler closure
     */
    @objc open func deleteDeviceInfo(_ completion:@escaping RestClient.DeleteDeviceHandler) {
        let resource = DeviceInfo.selfResource
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client
        {
            client.deleteDevice(url, completion: completion)
        }
        else
        {
            completion(NSError.clientUrlError(domain:DeviceInfo.self, code:0, client: client, url: url, resource: resource))
        }
    }
    
    /**
     Update the details of an existing device
     (For optional? parameters use nil if field doesn't need to be updated) //TODO: consider adding default nil value

     - parameter firmwareRevision?: firmware revision
     - parameter softwareRevision?: software revision
     - parameter completion:        UpdateDeviceHandler closure
     */
    @objc open func update(_ firmwareRevision:String?, softwareRevision:String?, notifcationToken: String?, completion:@escaping RestClient.UpdateDeviceHandler) {
        let resource = DeviceInfo.selfResource
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client
        {
            client.updateDevice(url, firmwareRevision: firmwareRevision, softwareRevision: softwareRevision, notificationToken: notifcationToken, completion: completion)
        }
        else
        {
            completion(nil, NSError.clientUrlError(domain:DeviceInfo.self, code:0, client: client, url: url, resource: resource))
        }
    }
    
    /**
     Retrieves a collection of all events that should be committed to this device
     
     - parameter commitsAfter: the last commit successfully applied. Query will return all subsequent commits which need to be applied.
     - parameter limit:        max number of profiles per page
     - parameter offset:       start index position for list of entities returned
     - parameter completion:   CommitsHandler closure
     */
    open func listCommits(commitsAfter:String?, limit:Int, offset:Int, completion:@escaping RestClient.CommitsHandler) {
        let resource = DeviceInfo.commitsResource
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client
        {
            client.commits(url, commitsAfter: commitsAfter, limit: limit, offset: offset, completion: completion)
        }
        else
        {
            completion(nil, NSError.clientUrlError(domain:DeviceInfo.self, code:0, client: client, url: url, resource: resource))
        }
    }
    
    @objc open func user(_ completion:@escaping RestClient.UserHandler) {
        let resource = DeviceInfo.userResource
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client
        {
            client.user(url, completion: completion)
        }
        else
        {
            completion(nil, NSError.clientUrlError(domain:DeviceInfo.self, code:0, client: client, url: url, resource: resource))
        }
    }
    
    internal func addNotificationToken(_ token:String, completion:@escaping RestClient.UpdateDeviceHandler) {
        let resource = DeviceInfo.selfResource
        let url = self.links?.url(resource)
        if  let url = url, let client = self.client
        {
            client.addDeviceProperty(url, propertyPath: "/notificationToken", propertyValue: token, completion: completion)
        }
        else
        {
            completion(nil, NSError.clientUrlError(domain:DeviceInfo.self, code:0, client: client, url: url, resource: resource))
        }
    }
    
    internal func updateNotificationTokenIfNeeded() {
        let newNotificationToken = FitpayNotificationsManager.sharedInstance.notificationsToken
        if newNotificationToken != "" {
            if newNotificationToken != self.notificationToken {
                if self.notificationToken != nil {
                    update(nil, softwareRevision: nil, notifcationToken: newNotificationToken, completion: {
                        [weak self] (device, error) in
                        if error == nil && device != nil {
                            log.debug("notificationToken updated to - \(device?.notificationToken)")
                            self?.notificationToken = device?.notificationToken
                        }
                    })
                } else {
                    addNotificationToken(newNotificationToken, completion: {
                        [weak self] (device, error) in
                        log.debug("notificationToken updated to - \(device?.notificationToken)")
                        if error == nil && device != nil {
                            self?.notificationToken = device?.notificationToken
                        }
                    })
                }
            }
        }
    }
}

open class CardRelationship : NSObject, ClientModel, Mappable, SecretApplyable
{
    internal var links:[ResourceLink]?
    open var creditCardId:String?
    open var pan:String?
    open var expMonth:Int?
    open var expYear:Int?
    
    internal var encryptedData:String?
    fileprivate static let selfResource = "self"
    internal weak var client:RestClient?
    
    public required init?(map: Map)
    {
        
    }
    
    open func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        creditCardId <- map["creditCardId"]
        encryptedData <- map["encryptedData"]
        pan <- map["pan"]
        expMonth <- map["expMonth"]
        expYear <- map["expYear"]
    }
    
    internal func applySecret(_ secret:Data, expectedKeyId:String?)
    {
        if let decryptedObj : CardRelationship = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret) {
            self.pan = decryptedObj.pan
            self.expMonth = decryptedObj.expMonth
            self.expYear = decryptedObj.expYear
        }
    }
    
    /**
     Get a single relationship
     
     - parameter completion:   RelationshipHandler closure
     */
    @objc open func relationship(_ completion:@escaping RestClient.RelationshipHandler) {
        let resource = CardRelationship.selfResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client
        {
            client.relationship(url, completion: completion)
        }
        else
        {
            completion(nil, NSError.clientUrlError(domain:CardRelationship.self, code:0, client: client, url: url, resource: resource))
        }
    }
}
