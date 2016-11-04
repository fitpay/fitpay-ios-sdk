
import ObjectMapper

open class Commit : NSObject, ClientModel, Mappable, SecretApplyable
{
    var links:[ResourceLink]?
    open var commitType:CommitType?
    open var payload:Payload?
    open var created:CLong?
    open var previousCommit:String?
    open var commit:String?
    
    fileprivate static let apduResponseResource = "apduResponse"
    
    internal weak var client:RestClient?
    
    internal var encryptedData:String?
    
    public required init?(map: Map)
    {
        
    }
    
    open func mapping(map: Map)
    {
        links <- (map["_links"], ResourceLinkTransformType())
        commitType <- map["commitType"]
        created <- map["createdTs"]
        previousCommit <- map["previousCommit"]
        commit <- map["commitId"]
        encryptedData <- map["encryptedData"]
    }
    
    internal func applySecret(_ secret:Data, expectedKeyId:String?)
    {
        self.payload = JWEObject.decrypt(self.encryptedData, expectedKeyId: expectedKeyId, secret: secret)
    }
    
    internal func confirmAPDU(_ completion:@escaping RestClient.ConfirmAPDUPackageHandler) {
        log.verbose("in the confirmAPDU method")
        guard self.commitType == CommitType.APDU_PACKAGE else {
            completion(NSError.unhandledError(Commit.self))
            return
        }
        
        let resource = Commit.apduResponseResource
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

public enum CommitType : String
{
    case CREDITCARD_CREATED = "CREDITCARD_CREATED"
    case CREDITCARD_DEACTIVATED = "CREDITCARD_DEACTIVATED"
    case CREDITCARD_ACTIVATED = "CREDITCARD_ACTIVATED"
    case CREDITCARD_REACTIVATED = "CREDITCARD_REACTIVATED"
    case CREDITCARD_DELETED = "CREDITCARD_DELETED"
    case RESET_DEFAULT_CREDITCARD = "RESET_DEFAULT_CREDITCARD"
    case SET_DEFAULT_CREDITCARD = "SET_DEFAULT_CREDITCARD"
    case APDU_PACKAGE = "APDU_PACKAGE"
}

open class Payload : NSObject, Mappable
{
    open var creditCard:CreditCard?
    internal var payloadDictionary:[String : AnyObject]?
    internal var apduPackage:ApduPackage?
    
    public required init?(map: Map)
    {
        
    }
    
    open func mapping(map: Map)
    {
        let info = map.JSON
        
        if let _ = info["creditCardId"]
        {
            self.creditCard = Mapper<CreditCard>().map(JSON: info)
        }
        else if let _ = info["packageId"]
        {
            self.apduPackage = Mapper<ApduPackage>().map(JSON: info)
        }
        
        self.payloadDictionary = info as [String : AnyObject]?
    }
}
