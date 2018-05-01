import ObjectMapper

open class Commit: NSObject, ClientModel, Mappable, SecretApplyable {

    open var commitType:CommitType? {
        return CommitType(rawValue: commitTypeString ?? "") ?? .UNKNOWN
    }
    open var commitTypeString: String?
    open var payload: Payload?
    open var created: CLong?
    open var previousCommit: String?
    open var commit: String?
    open var executedDuration: Int?
    
    public weak var client: RestClient? {
        didSet {
            payload?.creditCard?.client = self.client
        }
    }
    
    var links: [ResourceLink]?
    
    private static let apduResponseResourceKey = "apduResponse"
    private static let confirmResourceKey = "confirm"
    
    internal var encryptedData: String?
    
    public required init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        links <- (map["_links"], ResourceLinkTransformType())
        commitTypeString <- map["commitType"]
        created <- map["createdTs"]
        previousCommit <- map["previousCommit"]
        commit <- map["commitId"]
        encryptedData <- map["encryptedData"]
    }
    
    internal func applySecret(_ secret:Data, expectedKeyId:String?) {
        self.payload = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
        self.payload?.creditCard?.client = self.client
    }
    
    internal func confirmNonAPDUCommitWith(result: NonAPDUCommitState, completion: @escaping RestClient.ConfirmCommitHandler) {
        log.verbose("Confirming commit - \(self.commit ?? "")")
        
        guard self.commitType != CommitType.APDU_PACKAGE else {
            log.error("Trying send confirm for APDU commit but should be non APDU.")
            completion(NSError.unhandledError(Commit.self))
            return
        }
        
        let resource = Commit.confirmResourceKey
        guard let url = self.links?.url(resource) else {
            completion(nil)
            return
        }
        
        guard let client = self.client else {
            completion(NSError.clientUrlError(domain:Commit.self, code:0, client: nil, url: url, resource: resource))
            return
        }
        
        client.confirm(url, executionResult: result, completion: completion)
    }
    
    internal func confirmAPDU(_ completion:@escaping RestClient.ConfirmAPDUPackageHandler) {
        log.verbose("in the confirmAPDU method")
        guard self.commitType == CommitType.APDU_PACKAGE else {
            completion(NSError.unhandledError(Commit.self))
            return
        }
        
        let resource = Commit.apduResponseResourceKey
        guard let url = self.links?.url(resource) else {
            completion(NSError.clientUrlError(domain:Commit.self, code:0, client: client, url: nil, resource: resource))
            return
        }
        
        guard let client = self.client else {
            completion(NSError.clientUrlError(domain:Commit.self, code:0, client: nil, url: url, resource: resource))
            return
        }
        
        guard let apduPackage = self.payload?.apduPackage else {
            completion(NSError.unhandledError(Commit.self))
            return
        }
        
        log.verbose("apdu package \(apduPackage)")
        client.confirmAPDUPackage(url, package: apduPackage, completion: completion)
    }
}

public enum CommitType: String {
    case CREDITCARD_CREATED          = "CREDITCARD_CREATED"
    case CREDITCARD_DEACTIVATED      = "CREDITCARD_DEACTIVATED"
    case CREDITCARD_ACTIVATED        = "CREDITCARD_ACTIVATED"
    case CREDITCARD_REACTIVATED      = "CREDITCARD_REACTIVATED"
    case CREDITCARD_DELETED          = "CREDITCARD_DELETED"
    case RESET_DEFAULT_CREDITCARD    = "RESET_DEFAULT_CREDITCARD"
    case SET_DEFAULT_CREDITCARD      = "SET_DEFAULT_CREDITCARD"
    case APDU_PACKAGE                = "APDU_PACKAGE"
    case CREDITCARD_PROVISION_FAILED = "CREDITCARD_PROVISION_FAILED"
    case CREDITCARD_METADATA_UPDATED = "CREDITCARD_METADATA_UPDATED"
    case UNKNOWN                     = "UNKNOWN"
}

open class Payload: NSObject, Mappable {
    
    open var creditCard: CreditCard?
    
    internal var payloadDictionary: [String: Any]?
    internal var apduPackage: ApduPackage?
    
    public required init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        let info = map.JSON
        
        if let _ = info["creditCardId"] {
            self.creditCard = Mapper<CreditCard>().map(JSON: info)
        } else if let _ = info["packageId"] {
            self.apduPackage = Mapper<ApduPackage>().map(JSON: info)
        }
        
        self.payloadDictionary = info as [String :Any]?
    }
}
