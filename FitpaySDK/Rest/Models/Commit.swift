
open class Commit: NSObject, ClientModel, Serializable, SecretApplyable {
    
    open var commitType: CommitType? {
        return CommitType(rawValue: commitTypeString ?? "") ?? .UNKNOWN
    }
    open var commitTypeString: String?
    open var payload: Payload?
    open var created: CLong?
    open var previousCommit: String?
    open var commit: String?
    open var executedDuration: Int?
    
    weak var client: RestClient? {
        didSet {
            payload?.creditCard?.client = self.client
        }
    }

    var links: [ResourceLink]?
    var encryptedData: String?

    private static let apduResponseResourceKey = "apduResponse"
    private static let confirmResourceKey = "confirm"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case commitTypeString = "commitType"
        case created = "createdTs"
        case previousCommit
        case commit = "commitId"
        case encryptedData
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        commitTypeString = try? container.decode(.commitTypeString)
        created = try? container.decode(.created)
        previousCommit = try? container.decode(.previousCommit)
        commit = try? container.decode(.commit)
        encryptedData = try? container.decode(.encryptedData)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(commitTypeString, forKey: .commitTypeString)
        try? container.encode(created, forKey: .created)
        try? container.encode(previousCommit, forKey: .previousCommit)
        try? container.encode(commit, forKey: .commit)
        try? container.encode(encryptedData, forKey: .encryptedData)
    }

    
    func applySecret(_ secret:Data, expectedKeyId:String?) {
        self.payload = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
        self.payload?.creditCard?.client = self.client
    }
    
    func confirmNonAPDUCommitWith(result: NonAPDUCommitState, completion: @escaping RestClient.ConfirmCommitHandler) {
        log.verbose("Confirming commit - \(self.commit ?? "")")
        
        guard self.commitType != CommitType.APDU_PACKAGE else {
            log.error("Trying send confirm for APDU commit but should be non APDU.")
            completion(ErrorResponse.unhandledError(domain: Commit.self))
            return
        }
        
        let resource = Commit.confirmResourceKey
       guard let url = self.links?.url(resource) else {
            completion(nil)
            return
        }
        
        guard let client = self.client else {
            completion(ErrorResponse.clientUrlError(domain: Commit.self, client: nil, url: url, resource: resource))
            return
        }
        
        client.confirm(url, executionResult: result, completion: completion)
    }
    
    func confirmAPDU(_ completion:@escaping RestClient.ConfirmAPDUPackageHandler) {
        log.verbose("in the confirmAPDU method")
        guard self.commitType == CommitType.APDU_PACKAGE else {
            completion(ErrorResponse.unhandledError(domain: Commit.self))
            return
        }
        
        let resource = Commit.apduResponseResourceKey
        guard let url = self.links?.url(resource) else {
            completion(ErrorResponse.clientUrlError(domain: Commit.self, client: client, url: nil, resource: resource))
            return
        }
        
        guard let client = self.client else {
            completion(ErrorResponse.clientUrlError(domain: Commit.self, client: nil, url: url, resource: resource))
            return
        }
        
        guard let apduPackage = self.payload?.apduPackage else {
            completion(ErrorResponse.unhandledError(domain: Commit.self))
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

open class Payload: NSObject, Serializable {
    
    open var creditCard: CreditCard?
    
    var payloadDictionary: [String: Any]?
    var apduPackage: ApduPackage?
    
    private enum CodingKeys: String, CodingKey {
        case creditCardId
        case packageId
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apduPackage = try? ApduPackage(from: decoder)
        creditCard = try? CreditCard(from: decoder)

        self.payloadDictionary = try? container.decode([String : Any].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(creditCard, forKey: .creditCardId)
        try? container.encode(apduPackage, forKey: .packageId)
    }
}
