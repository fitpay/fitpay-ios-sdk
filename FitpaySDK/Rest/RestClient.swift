
import Foundation
import Alamofire
import AlamofireObjectMapper
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class CustomJSONArrayEncoding : ParameterEncoding {
    public static var `default`: CustomJSONArrayEncoding { return CustomJSONArrayEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var mutableRequest = try urlRequest.asURLRequest()
        let jsondata = try? JSONSerialization.data(withJSONObject: parameters!["params"]!, options: JSONSerialization.WritingOptions(rawValue: 0))
        if let jsondata = jsondata {
            mutableRequest.httpBody = jsondata
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return mutableRequest
    }
}


open class RestClient : NSObject
{
    /**
     FitPay uses conventional HTTP response codes to indicate success or failure of an API request. In general, codes in the 2xx range indicate success, codes in the 4xx range indicate an error that resulted from the provided information (e.g. a required parameter was missing, etc.), and codes in the 5xx range indicate an error with FitPay servers.

     Not all errors map cleanly onto HTTP response codes, however. When a request is valid but does not complete successfully (e.g. a card is declined), we return a 402 error code.

     - OK:               Everything worked as expected
     - BadRequest:       Often missing a required parameter
     - Unauthorized:     No valid API key provided
     - RequestFailed:    Parameters were valid but request failed
     - NotFound:         The requested item doesn't exist
     - ServerError[0-3]: Something went wrong on FitPay's end
     */
    public enum ErrorCode : Int, Error, RawIntValue
    {
        case ok = 200
        case badRequest = 400
        case unauthorized = 401
        case requestFailed = 402
        case notFound = 404
        case serverError0 = 500
        case serverError1 = 502
        case serverError2 = 503
        case serverError3 = 504
    }

    fileprivate static let fpKeyIdKey:String = "fp-key-id"

    fileprivate let defaultHeaders = ["Accept" : "application/json"]
    fileprivate var _session:RestSession
    internal var keyPair:SECP256R1KeyPair = SECP256R1KeyPair()

    lazy fileprivate var _manager:SessionManager =
    {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return SessionManager(configuration: configuration)
    }()

    fileprivate var key:EncryptionKey?

    public init(session:RestSession)
    {
        _session = session;
    }

    // MARK: User

    /**
     Completion handler

     - parameter ResultCollection<User>?: Provides ResultCollection<User> object, or nil if error occurs
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias ListUsersHandler = (ResultCollection<User>?, Error?)->Void

    /**
      Returns a list of all users that belong to your organization. The customers are returned sorted by creation date, with the most recently created customers appearing first

     - parameter limit:      Max number of profiles per page
     - parameter offset:     Start index position for list of entities returned
     - parameter completion: ListUsersHandler closure
     */
    open func listUsers(limit:Int, offset:Int, completion: ListUsersHandler)
    {
        //TODO: Implement or remove this
        assertionFailure("unimplemented functionality")
    }

    /**
     Completion handler
     
     - parameter [User]?: Provides created User object, or nil if error occurs
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias CreateUserHandler = (_ user:User?, _ error:NSError?)->Void
    
    /**
     Creates a new user within your organization
     
     - parameter firstName:  first name of the user
     - parameter lastName:   last name of the user
     - parameter birthDate:  birth date of the user in date format [YYYY-MM-DD]
     - parameter email:      email of the user
     - parameter completion: CreateUserHandler closure
     */
    open func createUser(
        _ email:String, password:String, firstName:String?, lastName:String?, birthDate:String?,
        termsVersion:String?, termsAccepted:String?, origin:String?, originAccountCreated:String?,
        clientId:String, completion:@escaping CreateUserHandler
    ) {
        log.verbose("request create user: \(email)")

        self.preparKeyHeader
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    log.verbose("got headers: \(headers)")
                    var parameters:[String : Any] = [:]
                    if (termsVersion != nil) {
                        parameters += ["termsVersion": termsVersion!]
                    }
                    if (termsAccepted != nil) {
                        parameters += ["termsAcceptedTsEpoch": termsAccepted!]
                    }
                    
                    if (origin != nil) {
                        parameters += ["origin": origin!]
                    }
                    
                    if (termsVersion != nil) {
                        parameters += ["originAccountCreatedTsEpoch": originAccountCreated!]
                    }

                    parameters["client_id"] = clientId

                    var rawUserInfo = [
                        "email" : email as AnyObject,
                        "pin" : password as AnyObject
                        ] as [String : Any]
                    if (firstName != nil) {
                        rawUserInfo += ["firstName" : firstName!]
                    }
                    
                    if (lastName != nil) {
                        rawUserInfo += ["lastName" : lastName!]
                    }
                    
                    if (birthDate != nil) {
                        rawUserInfo += ["birthDate" : birthDate!]
                    }
                    
                    if let userInfoJSON = rawUserInfo.JSONString
                    {
                        if let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: userInfoJSON, keyId:headers[RestClient.fpKeyIdKey]!)
                        {
                            if let encrypted = try? jweObject?.encrypt(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!)
                            {
                                parameters["encryptedData"] = encrypted
                            }
                        }
                    }
                    
                    log.verbose("user creation url: \(self._session.baseAPIURL)/users")
                    log.verbose("Headers: \(headers)")
                    log.verbose("user creation json: \(parameters)")
                    
                    let request = self._manager.request(self._session.baseAPIURL + "/users", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            (response:DataResponse<User>) in
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    resultValue.client = self
                                    completion(resultValue, nil)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(nil, error)
                    })
                }
        }
    }
    
    /**
     Completion handler
     
     - parameter user: Provides User object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias UserHandler = (_ user:User?, _ error:NSError?)->Void
    /**
     Retrieves the details of an existing user. You need only supply the unique user identifier that was returned upon user creation
     
     - parameter id:         user id
     - parameter completion: UserHandler closure
     */
    @objc open func user(id:String, completion:@escaping UserHandler)
    {
        self.prepareAuthAndKeyHeaders(
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(self._session.baseAPIURL + "/users/" + id, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(
                queue: DispatchQueue.global(), completionHandler:
                {
                    (response: DataResponse<User>) -> Void in
                    
                    DispatchQueue.main.async
                    {
                        () -> Void in
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    () -> Void in
                    completion(nil, error)
                })
            }
            
        })
    }
    
    /**
     Completion handler
     
     - parameter User?: Provides updated User object, or nil if error occurs
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias UpdateUserHandler = (_ user:User?, _ error:NSError?)->Void
    
    /**
     Update the details of an existing user
     
     - parameter id:                   user id
     - parameter firstName:            first name or nil if no change is required
     - parameter lastName:             last name or nil if no change is required
     - parameter birthDate:            birth date in date format [YYYY-MM-DD] or nil if no change is required
     - parameter originAccountCreated: origin account created in date format [TODO: specify date format] or nil if no change is required
     - parameter termsAccepted:        terms accepted in date format [TODO: specify date format] or nil if no change is required
     - parameter termsVersion:         terms version formatted as [0.0.0]
     - parameter completion:           UpdateUserHandler closure
     */
    internal func updateUser(_ url:String, firstName:String?, lastName:String?, birthDate:String?, originAccountCreated:String?, termsAccepted:String?, termsVersion:String?, completion:@escaping UpdateUserHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                (headers, error) -> Void in
                if let headers = headers
                {
                    
                    var operations = [Any]()
                    
                    if let firstName = firstName
                    {
                        operations.append(["op": "replace", "path": "/firstName", "value": firstName])
                    }
                    
                    if let lastName = lastName
                    {
                        operations.append(["op": "replace", "path": "/lastName", "value": lastName])
                    }
                    
                    if let birthDate = birthDate
                    {
                        operations.append(["op": "replace", "path": "/birthDate", "value": birthDate])
                    }
                    
                    if let originAccountCreated = originAccountCreated
                    {
                        operations.append(["op": "replace", "path": "/originAccountCreatedTs", "value": originAccountCreated])
                    }
                    
                    if let termsAccepted = termsAccepted
                    {
                        operations.append(["op": "replace", "path": "/termsAcceptedTs", "value": termsAccepted])
                    }
                    
                    if let termsVersion = termsVersion
                    {
                        operations.append(["op": "replace", "path": "/termsVersion", "value": termsVersion])
                    }
                    
                    var parameters = [String:AnyObject]()
                    
                    if let updateJSON = operations.JSONString
                    {
                        if let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: updateJSON, keyId:headers[RestClient.fpKeyIdKey]!)
                        {
                            if let encrypted = try? jweObject?.encrypt(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!)!
                            {
                                parameters["encryptedData"] = encrypted as AnyObject?
                            }
                        }
                    }

                    let request = self._manager.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    request.validate().responseObject(
                        queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self] (response: DataResponse<User>) -> Void in
                            
                            DispatchQueue.main.async
                            {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    completion(resultValue, response.result.error as NSError?)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                        })
                }
                else
                {
                    completion(nil, error)
                }
        }

    }
    
    /**
     Completion handler
     
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias DeleteUserHandler = (_ error:NSError?)->Void

    /**
     Delete a single user from your organization
     
     - parameter id:         user id
     - parameter completion: DeleteUserHandler closure
     */
    internal func deleteUser(_ url:String, completion:@escaping DeleteUserHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            (headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(url, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers)
                request.validate().responseString
                {
                    (response:DataResponse<String>) -> Void in
                    DispatchQueue.main.async
                    {
                        () -> Void in
                        completion(response.result.error as NSError?)
                    }
                }
            }
            else
            {
                completion(error)
            }
        }
    }
    
    
    /**
     Completion handler

     - parameter relationship: Provides created Relationship object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    public typealias CreateRelationshipHandler = (_ relationship:Relationship?, _ error:NSError?)->Void

    /**
     Creates a relationship between a device and a creditCard
     
     - parameter userId:       user id
     - parameter creditCardId: credit card id
     - parameter deviceId:     device id
     - parameter completion:   CreateRelationshipHandler closure
     */
    internal func createRelationship(_ url:String, creditCardId:String, deviceId:String, completion:@escaping CreateRelationshipHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            (headers, error) -> Void in
            if let headers = headers {
                let parameters = [
                    "creditCardId" : "\(creditCardId)",
                    "deviceId" : "\(deviceId)"
                ]
                let request = self._manager.request(url + "/relationships", method: .put, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
                request.validate().responseObject(
                queue: DispatchQueue.global(), completionHandler:
                {
                    (response: DataResponse<Relationship>) -> Void in
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                completion(nil, error)
            }
        }
    }
    
    /**
     Completion handler
     
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DeleteRelationshipHandler = (_ error:NSError?)->Void
    
    /**
    Completion handler
    
    - parameter creditCard: Provides credit card object, or nil if error occurs
    - parameter error:      Provides error object, or nil if no error occurs
    */
    public typealias CreateCreditCardHandler = (_ creditCard:CreditCard?, _ error:NSError?)->Void
    
    /**
    Completion handler
    
    - parameter result: Provides collection of credit cards, or nil if error occurs
    - parameter error:  Provides error object, or nil if no error occurs
    */
    public typealias CreditCardsHandler = (_ result:ResultCollection<CreditCard>?, _ error:NSError?) -> Void

    /**
     Completion handler
     
     - parameter creditCard: Provides credit card object, or nil if error occurs
     - parameter error:  Provides error object, or nil if no error occurs
     */
    public typealias CreditCardHandler = (_ creditCard:CreditCard?, _ error:NSError?)->Void
        
    /**
     Completion handler
     
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DeleteCreditCardHandler = (_ error:NSError?)->Void
    
    /**
     Completion handler
     
     - parameter creditCard: Provides credit card object, or nil if error occurs
     - parameter error:  Provides error object, or nil if no error occurs
     */
    public typealias UpdateCreditCardHandler = (_ creditCard:CreditCard?, _ error:NSError?) -> Void
    
    /**
     Completion handler

     - parameter pending: Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter card?:   Provides updated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error?:  Provides error object, or nil if no error occurs
     */
    public typealias AcceptTermsHandler = (_ pending:Bool, _ card:CreditCard?, _ error:NSError?)->Void
    
    /**
     Completion handler
     
     - parameter pending: Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter card:    Provides updated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:   Provides error object, or nil if no error occurs
     */
    public typealias DeclineTermsHandler = (_ pending:Bool, _ card:CreditCard?, _ error:NSError?)->Void
    
    /**
     Completion handler

     - parameter pending:     Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter creditCard:  Provides updated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:       Provides error object, or nil if no error occurs
     */
    public typealias MakeDefaultHandler = (_ pending:Bool, _ creditCard:CreditCard?, _ error:NSError?)->Void

    /**
     Completion handler

     - parameter pending:    Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter creditCard: Provides deactivated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:      Provides error object, or nil if no error occurs
     */
    public typealias DeactivateHandler = (_ pending:Bool, _ creditCard:CreditCard?, _ error:NSError?)->Void
    
    /**
     Completion handler

     - parameter Bool:        Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter CreditCard?: Provides reactivated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter ErrorType?:  Provides error object, or nil if no error occurs
     */
    public typealias ReactivateHandler = (_ pending:Bool, _ creditCard:CreditCard?, _ error:NSError?)->Void

    /**
     Completion handler
     - parameter pending:             Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that VerificationMethod object is nil in this case
     - parameter verificationMethod:  Provides VerificationMethod object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:               Provides error object, or nil if no error occurs
     */
    public typealias SelectVerificationTypeHandler = (_ pending:Bool, _ verificationMethod:VerificationMethod?, _ error:NSError?)->Void
    
    /**
     Completion handler
     
     - parameter pending:            Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that VerificationMethod object is nil in this case
     - parameter verificationMethod: Provides VerificationMethod object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    public typealias VerifyHandler = (_ pending:Bool, _ verificationMethod:VerificationMethod?, _ error:NSError?)->Void
    
    /**
     Completion handler
     
     - parameter relationship: Provides Relationship object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    public typealias RelationshipHandler = (_ relationship:Relationship?, _ error:NSError?)->Void
    
    /**
    Completion handler
    
    - parameter result: Provides ResultCollection<DeviceInfo> object, or nil if error occurs
    - parameter error: Provides error object, or nil if no error occurs
    */
    public typealias DevicesHandler = (_ result:ResultCollection<DeviceInfo>?, _ error:NSError?)->Void
    
    /**
    Completion handler

    - parameter device: Provides created DeviceInfo object, or nil if error occurs
    - parameter error: Provides error object, or nil if no error occurs
    */
    public typealias CreateNewDeviceHandler = (_ device:DeviceInfo?, _ error:NSError?)->Void

    /**
    Completion handler

    - parameter device: Provides existing DeviceInfo object, or nil if error occurs
    - parameter error: Provides error object, or nil if no error occurs
    */
    public typealias DeviceHandler = (_ device:DeviceInfo?, _ error:NSError?) -> Void
    
    /**
    Completion handler

    - parameter device: Provides updated DeviceInfo object, or nil if error occurs
    - parameter error: Provides error object, or nil if no error occurs
    */
    public typealias UpdateDeviceHandler = (_ device:DeviceInfo?, _ error:NSError?) -> Void

    /**
    Completion handler

    - parameter error: Provides error object, or nil if no error occurs
    */
    public typealias DeleteDeviceHandler = (_ error:NSError?) -> Void

    /**
     Completion handler

     - parameter commits: Provides ResultCollection<Commit> object, or nil if error occurs
     - parameter error:   Provides error object, or nil if no error occurs
    */
    public typealias CommitsHandler = (_ result:ResultCollection<Commit>?, _ error:NSError?)->Void
    
    /**
     Completion handler
     
     - parameter commit:    Provides Commit object, or nil if error occurs
     - parameter error:     Provides error object, or nil if no error occurs
     */
    public typealias CommitHandler = (_ commit:Commit?, _ error:Error?)->Void
    
    /**
     Completion handler

     - parameter transactions: Provides ResultCollection<Transaction> object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
    */
    public typealias TransactionsHandler = (_ result:ResultCollection<Transaction>?, _ error:NSError?)->Void

    /**
     Completion handler

     - parameter transaction: Provides Transaction object, or nil if error occurs
     - parameter error:       Provides error object, or nil if no error occurs
     */
    public typealias TransactionHandler = (_ transaction:Transaction?, _ error:NSError?)->Void

    /**
     Completion handler
    
     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    public typealias ConfirmAPDUPackageHandler = (_ error:NSError?)->Void

    /**
     Endpoint to allow for returning responses to APDU execution
     
     - parameter package:    ApduPackage object
     - parameter completion: ConfirmAPDUPackageHandler closure
     */
    open func confirmAPDUPackage(_ url:String, package:ApduPackage, completion: @escaping ConfirmAPDUPackageHandler)
    {
        guard package.packageId != nil else {
            completion(NSError.error(code: ErrorCode.badRequest, domain: RestClient.self, message: "packageId should not be nil"))
            return
        }
        
        self.prepareAuthAndKeyHeaders
        {
            (headers, error) -> Void in
            if let headers = headers {
                let request = self._manager.request(url, method: .post, parameters: package.responseDictionary, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseString
                {
                    (response:DataResponse<String>) -> Void in
                    DispatchQueue.main.async {
                        completion(response.result.error as NSError?)
                    }
                }
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(error)
                })
            }
        }
    }

    /**
     Completion handler

     - parameter asset: Provides Asset object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias AssetsHandler = (_ asset:Asset?, _ error:NSError?)->Void

    // MARK: EncryptionKeys

    /**
     Completion handler

     - parameter encryptionKey?: Provides created EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    internal typealias CreateEncryptionKeyHandler = (_ encryptionKey:EncryptionKey?, _ error:NSError?)->Void

    /**
     Creates a new encryption key pair
     
     - parameter clientPublicKey: client public key
     - parameter completion:      CreateEncryptionKeyHandler closure
     */
    internal func createEncryptionKey(clientPublicKey:String, completion:@escaping CreateEncryptionKeyHandler)
    {
        let headers = self.defaultHeaders
        let parameters = [
                "clientPublicKey" : clientPublicKey
        ]

        let request = _manager.request(self._session.baseAPIURL + "/config/encryptionKeys", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseObject(queue: DispatchQueue.global())
        {
            (response: DataResponse<EncryptionKey>) -> Void in

            DispatchQueue.main.async {
                if let resultError = response.result.error
                {
                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                    
                    completion(nil, error)
                }
                else if let resultValue = response.result.value
                {
                    completion(resultValue, response.result.error as NSError?)
                }
                else
                {
                    completion(nil, NSError.unhandledError(RestClient.self))
                }
            }
        }
    }

    /**
     Completion handler

     - parameter encryptionKey?: Provides EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    internal typealias EncryptionKeyHandler = (_ encryptionKey:EncryptionKey?, _ error:NSError?)->Void

    /**
     Retrieve and individual key pair
     
     - parameter keyId:      key id
     - parameter completion: EncryptionKeyHandler closure
     */
    internal func encryptionKey(_ keyId:String, completion:@escaping EncryptionKeyHandler)
    {
        let headers = self.defaultHeaders
        let request = _manager.request(self._session.baseAPIURL + "/config/encryptionKeys/" + keyId, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseObject(queue: DispatchQueue.global())
        {
            (response: DataResponse<EncryptionKey>) -> Void in
            
            DispatchQueue.main.async {
                if let resultError = response.result.error
                {
                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                    
                    completion(nil, error)
                }
                else if let resultValue = response.result.value
                {
                    completion(resultValue, nil)
                }
                else
                {
                    completion(nil, NSError.unhandledError(RestClient.self))
                }
            }
        }
        
    }

    /**
     Completion handler
     
     - parameter error?: Provides error object, or nil if no error occurs
     */
    internal typealias DeleteEncryptionKeyHandler = (_ error:Error?)->Void
    
    /**
     Deletes encryption key
     
     - parameter keyId:      key id
     - parameter completion: DeleteEncryptionKeyHandler
     */
    internal func deleteEncryptionKey(_ keyId:String, completion:@escaping DeleteEncryptionKeyHandler)
    {
        let headers = self.defaultHeaders
        let request = _manager.request(self._session.baseAPIURL + "/config/encryptionKeys/" + keyId, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseString
        {
            (response:DataResponse<String>) -> Void in
            DispatchQueue.main.async {
                completion(response.result.error)
            }
        }
    }
    
    typealias CreateKeyIfNeededHandler = CreateEncryptionKeyHandler
    
    fileprivate func createKeyIfNeeded(_ completion: @escaping CreateKeyIfNeededHandler)
    {
        if let key = self.key
        {
            completion(key, nil)
        }
        else
        {
            self.createEncryptionKey(clientPublicKey: self.keyPair.publicKey!, completion:
            {
                [unowned self](encryptionKey, error) -> Void in
                
                if let error = error
                {
                    completion(nil, error)
                }
                else if let encryptionKey = encryptionKey
                {
                    self.key = encryptionKey
                    completion(self.key, nil)
                }
            })
        }
    }

    
    // MARK: Request Signature Helpers
    typealias CreateAuthHeaders = (_ headers:[String:String]?, _ error:NSError?) -> Void

    fileprivate func createAuthHeaders(_ completion:CreateAuthHeaders)
    {
        if self._session.isAuthorized
        {
            completion(["Authorization" : "Bearer " + self._session.accessToken!], nil)
        }
        else
        {
            completion(nil, NSError.error(code: ErrorCode.unauthorized, domain: RestClient.self, message: "\(ErrorCode.unauthorized)"))
        }
    }
 
    fileprivate func skipAuthHeaders(_ completion:CreateAuthHeaders)
    {
        // do nothing
        completion(self.defaultHeaders, nil)
    }


    typealias PrepareAuthAndKeyHeaders = (_ headers:[String:String]?, _ error:NSError?) -> Void
    fileprivate func prepareAuthAndKeyHeaders(_ completion:@escaping PrepareAuthAndKeyHeaders)
    {
        self.createAuthHeaders
        {
            [unowned self](headers, error) -> Void in
            
            if let error = error
            {
                completion(nil, error)
            }
            else
            {
                self.createKeyIfNeeded(
                {
                    (encryptionKey, keyError) -> Void in
                    
                    if let keyError = keyError
                    {
                        completion(nil, keyError)
                    }
                    else
                    {
                        completion(headers! + [RestClient.fpKeyIdKey : encryptionKey!.keyId!], nil)
                    }
                })
            }
            
        }
    }
    
    typealias PrepareKeyHeader = (_ headers:[String:String]?, _ error:NSError?) -> Void

    fileprivate func preparKeyHeader(_ completion:@escaping PrepareAuthAndKeyHeaders)
    {
        self.skipAuthHeaders
            {
                [unowned self](headers, error) -> Void in
                
                if let error = error
                {
                    completion(nil, error)
                }
                else
                {
                    self.createKeyIfNeeded(
                        {
                            (encryptionKey, keyError) -> Void in
                            
                            if let keyError = keyError
                            {
                                completion(nil, keyError)
                            }
                            else
                            {
                                completion(headers! + [RestClient.fpKeyIdKey : encryptionKey!.keyId!], nil)
                            }
                    })
                }
                
        }
    }

    
    // MARK: Hypermedia-driven implementation
    
    // MARK: Credit Card
    internal func createCreditCard(_ url:String, pan:String, expMonth:Int, expYear:Int, cvv:String, name:String,
        street1:String, street2:String, street3:String, city:String, state:String, postalCode:String, country:String,
        completion:@escaping CreateCreditCardHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                var parameters:[String : String] = [:]
                
                let rawCard = [
                    "pan" : pan as AnyObject,
                    "expMonth" : expMonth as AnyObject,
                    "expYear" : expYear as AnyObject,
                    "cvv" : cvv as AnyObject,
                    "name" : name as AnyObject,
                    "address" : [
                        "street1" : street1,
                        "street2" : street2,
                        "street3" : street3,
                        "city" : city,
                        "state" : state,
                        "postalCode" : postalCode,
                        "country" : country
                    ]
                    ] as [String : Any]
                
                if let cardJSON = rawCard.JSONString
                {
                    if let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: cardJSON, keyId:headers[RestClient.fpKeyIdKey]!)
                    {
                        if let encrypted = try? jweObject?.encrypt(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!)
                        {
                            parameters["encryptedData"] = encrypted
                        }
                    }
                }
                
                let request = self._manager.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                    {
                        (response:DataResponse<CreditCard>) -> Void in
                        
                        DispatchQueue.main.async {
                            if let resultError = response.result.error
                            {
                                let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                completion(nil, error)
                            }
                            else if let resultValue = response.result.value
                            {
                                resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                resultValue.client = self
                                completion(resultValue, nil)
                            }
                            else
                            {
                                completion(nil, NSError.unhandledError(RestClient.self))
                            }
                        }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                        () -> Void in
                        completion(nil, error)
                })
            }
        }
    }

    internal func creditCards(_ url:String, excludeState:[String], limit:Int, offset:Int, completion:@escaping CreditCardsHandler)
    {
        let parameters:[String : AnyObject] = ["excludeState" : excludeState.joined(separator: ",") as AnyObject, "limit" : limit as AnyObject, "offest" : offset as AnyObject]
        self.creditCards(url, parameters: parameters, completion: completion)
    }
    
    internal func creditCards(_ url:String, parameters:[String:AnyObject]?, completion:@escaping CreditCardsHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                    
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            (response:DataResponse<ResultCollection<CreditCard>>) -> Void in
                            
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    
                                    resultValue.client = self
                                    
                                    completion(resultValue, nil)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(nil, error)
                    })
                }
        }
    }

    internal func deleteCreditCard(_ url:String, completion:@escaping DeleteCreditCardHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(url, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers)
                request.validate().responseData(queue: DispatchQueue.global(), completionHandler:
                {
                    (response:DataResponse<Data>) -> Void in
                    
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            completion(error)
                        }
                        else if let _ = response.result.value
                        {
                            completion(nil)
                        }
                        else
                        {
                            completion(NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    () -> Void in
                    completion(error)
                })
            }
        }
    }
    
    internal func updateCreditCard(_ url:String, name:String?, street1:String?, street2:String?, city:String?, state:String?, postalCode:String?, countryCode:String?, completion:@escaping UpdateCreditCardHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    var operations:[[String : String]] = []
                    
                    var parameters:[String : Any] = [:]
                    
                    if let name = name
                    {
                        operations.append([
                            "op": "replace", "path": "/name", "value" : name
                            ])
                    }
                    
                    if let street1 = street1
                    {
                        operations.append([
                            "op": "replace", "path": "/address/street1", "value" : street1
                            ])
                    }
                    
                    if let street2 = street2
                    {
                        operations.append([
                            "op": "replace", "path": "/address/street2", "value" : street2
                            ])
                    }
                    
                    if let city = city
                    {
                        operations.append([
                            "op": "replace", "path": "/address/city", "value" : city
                            ])
                    }
                    
                    if let state = state
                    {
                        operations.append([
                            "op": "replace", "path": "/address/state", "value" : state
                            ])
                    }
                    
                    if let postalCode = postalCode
                    {
                        operations.append([
                            "op": "replace", "path": "/address/postalCode", "value" : postalCode
                            ])
                    }
                    
                    if let countryCode = countryCode
                    {
                        operations.append([
                            "op": "replace", "path": "/address/countryCode", "value" : countryCode
                            ])
                    }
                    
                    if let updateJSON = operations.JSONString
                    {
                        if let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: updateJSON, keyId:headers[RestClient.fpKeyIdKey]!)
                        {
                            if let encrypted = try? jweObject?.encrypt(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!)!
                            {
                                parameters["encryptedData"] = encrypted
                            }
                        }
                    }
                    
                    let request = self._manager.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self](response:DataResponse<CreditCard>) -> Void in
                            
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    resultValue.client = self
                                    completion(resultValue, nil)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(nil, error)
                    })
                }
        }
    }
    
    internal func acceptTerms(_ url:String, completion:@escaping AcceptTermsHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                    {
                        [unowned self](response:DataResponse<CreditCard>) -> Void in
                        
                        DispatchQueue.main.async {
                            if let resultError = response.result.error
                            {
                                let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                completion(false, nil, error)
                            }
                            else if let value = response.result.value
                            {
                                value.client = self
                                completion(false, value, nil)
                            }
                            else if (response.response != nil && response.response!.statusCode == 202)
                            {
                                completion(true, nil, nil)
                            }
                            else
                            {
                                completion(false, nil, NSError.unhandledError(RestClient.self))
                            }
                        }
                    })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                        () -> Void in
                        completion(false, nil, error)
                })
            }
        }
    }
    
    internal func declineTerms(_ url:String, completion:@escaping DeclineTermsHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    let request = self._manager.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            (response:DataResponse<CreditCard>) -> Void in
                            
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(false, nil, error)
                                }
                                else if let value = response.result.value
                                {
                                    value.client = self
                                    completion(false, value, nil)
                                }
                                else if (response.response != nil && response.response!.statusCode == 202)
                                {
                                    completion(true, nil, nil)
                                }
                                else
                                {
                                    completion(false, nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(false, nil, error)
                    })
                }
        }
    }
    
    internal func selectVerificationType(_ url:String, completion:@escaping SelectVerificationTypeHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                    {
                        [unowned self](response:DataResponse<VerificationMethod>) -> Void in
                        
                        DispatchQueue.main.async {
                            if let resultError = response.result.error
                            {
                                let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                completion(false, nil, error)
                            }
                            else if let resultValue = response.result.value
                            {
                                resultValue.client = self
                                completion(false, resultValue, nil)
                            }
                            else
                            {
                                if let statusCode = response.response?.statusCode
                                {
                                    switch statusCode
                                    {
                                    case 202:
                                        completion(true, nil, nil)
                                        
                                    default:
                                        completion(false, nil, NSError.unhandledError(RestClient.self))
                                    }
                                }
                                else
                                {
                                    completion(false, nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                        }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                        completion(false, nil, error)
                })
            }
        }
    }
    
    internal func verify(_ url:String, verificationCode:String, completion:@escaping VerifyHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                let params = [
                    "verificationCode" : verificationCode
                ]
                
                let request = self._manager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                    {
                        [](response:DataResponse<VerificationMethod>) -> Void in
                        
                        DispatchQueue.main.async {
                            if let resultError = response.result.error
                            {
                                let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                completion(false, nil, error)
                            }
                            else if let resultValue = response.result.value
                            {
                                resultValue.client = self
                                completion(false, resultValue, nil)
                            }
                            else
                            {
                                if let statusCode = response.response?.statusCode
                                {
                                    switch statusCode
                                    {
                                    case 202:
                                        completion(true, nil, nil)
                                        
                                    default:
                                        completion(false, nil, NSError.unhandledError(RestClient.self))
                                    }
                                }
                                else
                                {
                                    completion(false, nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                        }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                        completion(false, nil, error)
                    })
                }
        }
    }
    
    internal func deactivate(_ url:String, causedBy:CreditCardInitiator, reason:String, completion:@escaping DeactivateHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    let parameters = ["causedBy" : causedBy.rawValue, "reason" : reason]
                    let request = self._manager.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self](response:DataResponse<CreditCard>) -> Void in
                            
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(false, nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    completion(false, resultValue, nil)
                                }
                                else
                                {
                                    if let statusCode = response.response?.statusCode
                                    {
                                        switch statusCode
                                        {
                                        case 202:
                                            completion(true, nil, nil)
                                            
                                        default:
                                            completion(false, nil, NSError.unhandledError(RestClient.self))
                                        }
                                    }
                                    else
                                    {
                                        completion(false, nil, NSError.unhandledError(RestClient.self))
                                    }
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(false, nil, error)
                    })
                }
        }
    }
    
    internal func reactivate(_ url:String, causedBy:CreditCardInitiator, reason:String, completion:@escaping ReactivateHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    let parameters = ["causedBy" : causedBy.rawValue, "reason" : reason]
                    let request = self._manager.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self](response:DataResponse<CreditCard>) -> Void in
                            
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(false, nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    completion(false, resultValue, nil)
                                }
                                else
                                {
                                    if let statusCode = response.response?.statusCode
                                    {
                                        switch statusCode
                                        {
                                        case 202:
                                            completion(true, nil, nil)
                                            
                                        default:
                                            completion(false, nil, NSError.unhandledError(RestClient.self))
                                        }
                                    }
                                    else
                                    {
                                        completion(false, nil, NSError.unhandledError(RestClient.self))
                                    }
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(false, nil, error)
                    })
                }
        }
    }
    
    internal func retrieveCreditCard(_ url:String, completion:@escaping CreditCardHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self](headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                    {
                        [unowned self](response:DataResponse<CreditCard>) -> Void in
                        
                        DispatchQueue.main.async {
                            if let resultError = response.result.error
                            {
                                let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                completion(nil, error)
                            }
                            else if let resultValue = response.result.value
                            {
                                resultValue.client = self
                                resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                completion(resultValue, nil)
                            }
                            else
                            {
                                completion(nil, NSError.unhandledError(RestClient.self))
                            }
                        }
                    })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                        () -> Void in
                        completion(nil, error)
                })
            }
        }
    }

    internal func makeDefault(_ url:String, completion:@escaping MakeDefaultHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self](headers, error) -> Void in
                if let headers = headers
                {
                    let request = self._manager.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self](response:DataResponse<CreditCard>) -> Void in
                            
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    completion(false, nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    completion(false, resultValue, nil)
                                }
                                else
                                {
                                    if let statusCode = response.response?.statusCode
                                    {
                                        switch statusCode
                                        {
                                        case 202:
                                            completion(true, nil, nil)
                                            
                                        default:
                                            completion(false, nil, NSError.unhandledError(RestClient.self))
                                        }
                                    }
                                    else
                                    {
                                        completion(false, nil, NSError.unhandledError(RestClient.self))
                                    }
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            () -> Void in
                            completion(false, nil, error)
                    })
                }
        }
        
    }
    
    // MARK: Devices
    internal func devices(_ url:String, limit:Int, offset:Int, completion:@escaping DevicesHandler)
    {
        let parameters = [
            "limit" : "\(limit)",
            "offset" : "\(offset)"
        ]

        self.devices(url, parameters: parameters as [String : AnyObject]?, completion: completion)
    }
    
    internal func devices(_ url:String, parameters:[String : AnyObject]?, completion:@escaping DevicesHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self] (headers, error) -> Void in
                if let headers = headers {
                    
                    let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                    request.validate().responseObject(
                        queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self] (response: DataResponse<ResultCollection<DeviceInfo>>) -> Void in
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    
                                    completion(resultValue, response.result.error as NSError?)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                        })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                        completion(nil, error)
                    })
                }
        }
    }


    internal func createNewDevice(_ url:String, deviceType:String, manufacturerName:String, deviceName:String,
        serialNumber:String, modelNumber:String, hardwareRevision:String, firmwareRevision:String,
        softwareRevision:String, systemId:String, osName:String, licenseKey:String, bdAddress:String,
        secureElementId:String, pairing:String, completion:@escaping CreateNewDeviceHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self] (headers, error) -> Void in
            if let headers = headers {
                let params = [
                    "deviceType" : deviceType,
                    "manufacturerName" : manufacturerName,
                    "deviceName" : deviceName,
                    "serialNumber" : serialNumber,
                    "modelNumber" : modelNumber,
                    "hardwareRevision" : hardwareRevision,
                    "firmwareRevision" : firmwareRevision,
                    "softwareRevision" : softwareRevision,
                    "systemId" : systemId,
                    "osName" : osName,
                    "licenseKey" : licenseKey,
                    "bdAddress" : bdAddress,
                    "secureElement" : [
                        "secureElementId" : secureElementId
                    ],
                    "pairingTs" : pairing
                ] as [String : Any]
                let request = self._manager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(
                queue: DispatchQueue.global(), completionHandler:
                {
                    [unowned self] (response: DataResponse<DeviceInfo>) -> Void in
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            
                            resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
    
    internal func deleteDevice(_ url:String, completion:@escaping DeleteDeviceHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            [unowned self] (headers, error) -> Void in
            if let headers = headers {
                let request = self._manager.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseString
                {
                    (response:DataResponse<String>) -> Void in
                    DispatchQueue.main.async {
                        completion(response.result.error as NSError?)
                    }
                }
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(error)
                })
            }
        }
    }
    
    internal func updateDevice(_ url:String, firmwareRevision:String?, softwareRevision:String?, notificationToken: String?,
        completion:@escaping UpdateDeviceHandler)
    {
        var paramsArray = [Any]()
        if let firmwareRevision = firmwareRevision {
            paramsArray.append(["op" : "replace", "path" : "/firmwareRevision", "value" : firmwareRevision])
        }
        
        if let softwareRevision = softwareRevision {
            paramsArray.append(["op" : "replace", "path" : "/softwareRevision", "value" : softwareRevision])
        }
        
        if let notificationToken = notificationToken {
            paramsArray.append(["op" : "replace", "path" : "/notificationToken", "value" : notificationToken])
        }
        
        self.prepareAuthAndKeyHeaders
        {
            [unowned self] (headers, error) -> Void in
            if let headers = headers {
                let params = ["params" : paramsArray]
                let request = self._manager.request(url, method: .patch, parameters: params, encoding: CustomJSONArrayEncoding.default, headers: headers)
                request.validate().responseObject(
                    queue: DispatchQueue.global(), completionHandler:
                {
                    [unowned self] (response: DataResponse<DeviceInfo>) -> Void in
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                            
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
    
    internal func addDeviceProperty(_ url:String, propertyPath:String, propertyValue:String, completion:@escaping UpdateDeviceHandler) {
        var paramsArray = [Any]()
        paramsArray.append(["op" : "add", "path" : propertyPath, "value" : propertyValue])
        self.prepareAuthAndKeyHeaders
            {
                [unowned self] (headers, error) -> Void in
                if let headers = headers {
                    let params = ["params" : paramsArray]
                    let request = self._manager.request(url, method: .patch, parameters: params, encoding: CustomJSONArrayEncoding.default, headers: headers)
                    request.validate().responseObject(
                        queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self] (response: DataResponse<DeviceInfo>) -> Void in
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    
                                    completion(resultValue, response.result.error as NSError?)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                        })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            completion(nil, error)
                    })
                }
        }
    }
    
    open func commits(_ url:String, commitsAfter:String?, limit:Int, offset:Int,
        completion:@escaping CommitsHandler)
    {
        var parameters = [
            "limit" : "\(limit)",
            "offset" : "\(offset)"
        ]
        
        if (commitsAfter != nil && commitsAfter?.characters.count > 0) {
            parameters["commitsAfter"] = commitsAfter!
        }
        
        self.prepareAuthAndKeyHeaders
        {
            [unowned self] (headers, error) -> Void in
            if let headers = headers {
                
                let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler: {
                    [unowned self] (response: DataResponse<ResultCollection<Commit>>) -> Void in
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
    
    internal func commits(_ url:String, parameters:[String : AnyObject]?,
        completion:@escaping CommitsHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                [unowned self] (headers, error) -> Void in
                if let headers = headers {
                    
                    let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                    request.validate().responseObject(
                        queue: DispatchQueue.global(), completionHandler:
                        {
                            [unowned self] (response: DataResponse<ResultCollection<Commit>>) -> Void in
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                                    completion(resultValue, response.result.error as NSError?)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                        })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            completion(nil, error)
                    })
                }
        }
    }
    
    // MARK: User
    open func user(_ url:String, completion:@escaping UserHandler)
    {
        self.prepareAuthAndKeyHeaders(
        {
            [unowned self] (headers, error) -> Void in
            if let headers = headers
            {
                let request = self._manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                {
                    [unowned self] (response: DataResponse<User>) -> Void in
                    
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        })
    }
    
    
    internal func relationship(_ url:String, completion:@escaping RelationshipHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            (headers, error) -> Void in
            if let headers = headers {
                let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
                request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                {
                    (response: DataResponse<Relationship>) -> Void in
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            completion(resultValue, response.result.error as NSError?)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                completion(nil, error)
            }
        }
    }
    
    internal func deleteRelationship(_ url:String, completion:@escaping DeleteRelationshipHandler)
    {
        self.prepareAuthAndKeyHeaders
        {
            (headers, error) -> Void in
            if let headers = headers {
                let request = self._manager.request(url, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers)
                request.validate().responseString
                {
                    (response:DataResponse<String>) -> Void in
                    DispatchQueue.main.async {
                        completion(response.result.error as NSError?)
                    }
                }
            }
            else
            {
                completion(error)
            }
        }
    }

    // MARK: Transactions
    internal func transactions(_ url:String, limit:Int, offset:Int, completion:@escaping TransactionsHandler)
    {
        let parameters = [
            "limit" : "\(limit)",
            "offset" : "\(offset)",
        ]
        
        self.transactions(url, parameters: parameters as [String : AnyObject]?, completion: completion)
    }
    
    internal func transactions(_ url:String, parameters:[String : AnyObject]?, completion:@escaping TransactionsHandler)
    {
        self.prepareAuthAndKeyHeaders
            {
                (headers, error) -> Void in
                if let headers = headers {
                    let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                    request.validate().responseObject(queue: DispatchQueue.global(), completionHandler:
                        {
                            (response: DataResponse<ResultCollection<Transaction>>) -> Void in
                            DispatchQueue.main.async {
                                if let resultError = response.result.error
                                {
                                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                                    
                                    completion(nil, error)
                                }
                                else if let resultValue = response.result.value
                                {
                                    resultValue.client = self
                                    completion(resultValue, response.result.error as NSError?)
                                }
                                else
                                {
                                    completion(nil, NSError.unhandledError(RestClient.self))
                                }
                            }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                            completion(nil, error)
                    })
                }
        }
    }

    internal func assets(_ url:String, completion:@escaping AssetsHandler)
    {
        let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
        
        DispatchQueue.global().async(execute: {
            request.responseData
            {
                (response:DataResponse<Data>) -> Void in
                if let resultError = response.result.error
                {
                    let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                    
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
                else if let resultValue = response.result.value
                {
                    var asset:Asset?
                    if let image = UIImage(data: resultValue)
                    {
                        asset = Asset(image: image)
                    }
                    else if let string = resultValue.UTF8String
                    {
                        asset = Asset(text: string)
                    }
                    else
                    {
                        asset = Asset(data: resultValue)
                    }
                    
                    DispatchQueue.main.async {
                        completion(asset, nil)
                    }
                }
                else
                {
                    DispatchQueue.main.async {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        })
    }
    
    
    internal func collectionItems<T>(_ url:String, completion:@escaping (_ resultCollection:ResultCollection<T>?, _ error:Error?) -> Void) -> T?
    {
        self.prepareAuthAndKeyHeaders
        {
            (headers, error) -> Void in
            if let headers = headers {
                let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
                request.validate().responseObject(
                queue: DispatchQueue.global(), completionHandler:
                {
                    (response: DataResponse<ResultCollection<T>>) -> Void in
                    DispatchQueue.main.async {
                        if let resultError = response.result.error
                        {
                            let error = NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestClient.self, data: response.data, alternativeError: resultError as NSError?)
                            
                            completion(nil, error)
                        }
                        else if let resultValue = response.result.value
                        {
                            resultValue.client = self
                            resultValue.applySecret(self.keyPair.generateSecretForPublicKey(self.key!.serverPublicKey!)!, expectedKeyId:headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error)
                        }
                        else
                        {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                })
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
        
        return nil
    }
}

/**
 Retrieve an individual asset (i.e. terms and conditions)
 
 - parameter completion:  AssetsHandler closure
 */
public protocol AssetRetrivable
{
    func retrieveAsset(_ completion:@escaping RestClient.AssetsHandler)
}
