import Foundation

open class Commit: NSObject, ClientModel, Serializable, SecretApplyable {
    
    open var commitType: CommitType? {
        return CommitType(rawValue: commitTypeString ?? "") ?? .unknown
    }
    open var commitTypeString: String?
    open var payload: Payload?
    open var created: CLong?
    open var previousCommit: String?
    open var commitId: String?
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
        case commitId
        case encryptedData
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        commitTypeString = try? container.decode(.commitTypeString)
        created = try? container.decode(.created)
        previousCommit = try? container.decode(.previousCommit)
        commitId = try? container.decode(.commitId)
        encryptedData = try? container.decode(.encryptedData)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(commitTypeString, forKey: .commitTypeString)
        try? container.encode(created, forKey: .created)
        try? container.encode(previousCommit, forKey: .previousCommit)
        try? container.encode(commitId, forKey: .commitId)
        try? container.encode(encryptedData, forKey: .encryptedData)
    }
    
    // MARK: - Functions
    
    func applySecret(_ secret: Data, expectedKeyId: String?) {
        self.payload = JWE.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
        self.payload?.creditCard?.client = self.client
    }
    
    func confirmNonAPDUCommitWith(result: NonAPDUCommitState, completion: @escaping RestClient.ConfirmHandler) {
        guard self.commitType != CommitType.apduPackage else {
            log.error("COMMIT: Trying send confirm for APDU commit but should be non APDU.")
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
        
        log.verbose("COMMIT: Confirming Non-APDU commit - \(commitId ?? "")")
        client.confirm(url, executionResult: result, completion: completion)
    }
    
    func confirmAPDU(_ completion: @escaping RestClient.ConfirmHandler) {
        guard self.commitType == CommitType.apduPackage else {
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
        
        log.verbose("COMMIT: Confirming APDU commit - \(commitId ?? "")")
        client.confirmAPDUPackage(url, package: apduPackage, completion: completion)
    }
    
}
