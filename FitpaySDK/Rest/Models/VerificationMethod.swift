import ObjectMapper

public enum VerificationMethodType: String {
    case TEXT_TO_CARDHOLDER_NUMBER          = "TEXT_TO_CARDHOLDER_NUMBER",
        EMAIL_TO_CARDHOLDER_ADDRESS         = "EMAIL_TO_CARDHOLDER_ADDRESS",
        CARDHOLDER_TO_CALL_AUTOMATED_NUMBER = "CARDHOLDER_TO_CALL_AUTOMATED_NUMBER",
        CARDHOLDER_TO_CALL_MANNED_NUMBER    = "CARDHOLDER_TO_CALL_MANNED_NUMBER",
        CARDHOLDER_TO_VISIT_WEBSITE         = "CARDHOLDER_TO_VISIT_WEBSITE",
        CARDHOLDER_TO_USE_MOBILE_APP        = "CARDHOLDER_TO_USE_MOBILE_APP",
        ISSUER_TO_CALL_CARDHOLDER_NUMBER    = "ISSUER_TO_CALL_CARDHOLDER_NUMBER"
}

public enum VerificationState: String {
    case AVAILABLE_FOR_SELECTION = "AVAILABLE_FOR_SELECTION",
        AWAITING_VERIFICATION    = "AWAITING_VERIFICATION",
        EXPIRED                  = "EXPIRED",
        VERIFIED                 = "VERIFIED"
}

public enum VerificationResult: String {
    case SUCCESS                        = "SUCCESS",
        INCORRECT_CODE                  = "INCORRECT_CODE",
        INCORRECT_CODE_RETRIES_EXCEEDED = "INCORRECT_CODE_RETRIES_EXCEEDED",
        EXPIRED_CODE                    = "EXPIRED_CODE",
        INCORRECT_TAV                   = "INCORRECT_TAV",
        EXPIRED_SESSION                 = "EXPIRED_SESSION"
}

@objcMembers
open class VerificationMethod: NSObject, ClientModel, Mappable {
    internal var links: [ResourceLink]?
    open var verificationId: String?
    open var state: VerificationState?
    open var methodType: VerificationMethodType?
    open var value: String?
    open var verificationResult: VerificationResult?
    open var created: String?
    open var createdEpoch: TimeInterval?
    open var lastModified: String?
    open var lastModifiedEpoch: TimeInterval?
    open var verified: String?
    open var verifiedEpoch: TimeInterval?
    open var appToAppContext: A2AContext?

    public weak var client: RestClient?

    open var selectAvailable: Bool {
        return self.links?.url(VerificationMethod.selectResourceKey) != nil
    }

    open var verifyAvailable: Bool {
        return self.links?.url(VerificationMethod.verifyResourceKey) != nil
    }

    open var cardAvailable: Bool {
        return self.links?.url(VerificationMethod.cardResourceKey) != nil
    }

    public required init?(map: Map){
    }
    
    private static let selectResourceKey = "select"
    private static let verifyResourceKey = "verify"
    private static let cardResourceKey = "card"

    open func mapping(map: Map) {
        self.links <- (map["_links"], ResourceLinkTransformType())
        self.verificationId <- map["verificationId"]
        self.state <- map["state"]
        self.methodType <- map["methodType"]
        self.value <- map["value"]
        self.verificationResult <- map["verificationResult"]
        self.created <- map["createdTs"]
        self.createdEpoch <- (map["createdTsEpoch"], NSTimeIntervalTransform())
        self.lastModified <- map["lastModifiedTs"]
        self.lastModifiedEpoch <- (map["lastModifiedTsEpoch"], NSTimeIntervalTransform())
        self.verified <- map["verifiedTs"]
        self.verifiedEpoch <- (map["verifiedTsEpoch"], NSTimeIntervalTransform())
        self.appToAppContext <- map["appToAppContext"]
    }

    /**
     When an issuer requires additional authentication to verfiy the identity of the cardholder, this indicates the user has selected the specified verification method by the indicated verificationTypeId
     
     - parameter completion:    VerifyHandler closure
     */
    @objc open func selectVerificationType(_ completion: @escaping RestClient.VerifyHandler) {
        let resource = VerificationMethod.selectResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.selectVerificationType(url, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: VerificationMethod.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     If a verification method is selected that requires an entry of a pin code, this transition will be available. Not all verification methods will include a secondary verification step through the FitPay API
     
     - parameter completion:    VerifyHandler closure
     */
    @objc open func verify(_ verificationCode: String, completion: @escaping RestClient.VerifyHandler) {
        let resource = VerificationMethod.verifyResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.verify(url, verificationCode: verificationCode, completion: completion)
        } else {
            completion(false, nil, NSError.clientUrlError(domain: VerificationMethod.self, code: 0, client: client, url: url, resource: resource))
        }
    }

    /**
     Retrieves the details of an existing credit card. You need only supply the uniqueidentifier that was returned upon creation.
     
     - parameter completion:    CreditCardHandler closure
     */
    @objc open func retrieveCreditCard(_ completion: @escaping RestClient.CreditCardHandler) {
        let resource = VerificationMethod.cardResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.retrieveCreditCard(url, completion: completion)
        } else {
            completion(nil, NSError.clientUrlError(domain: VerificationMethod.self, code: 0, client: client, url: url, resource: resource))
        }
    }
}

internal class VerificationMethodTransformType: TransformType {
    typealias Object = [VerificationMethod]
    typealias JSON = [[String: Any]]

    func transformFromJSON(_ value: Any?) -> Array<VerificationMethod>? {
        if let items = value as? [[String: Any]] {
            var list = [VerificationMethod]()

            for raw in items {
                if let item = Mapper<VerificationMethod>().map(JSON: raw) {
                    list.append(item)
                }
            }

            return list
        }

        return nil
    }

    func transformToJSON(_ value: [VerificationMethod]?) -> [[String: Any]]? {
        return nil
    }
}
