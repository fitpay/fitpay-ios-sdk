
import Foundation
import Alamofire
import AlamofireObjectMapper

class CustomJSONArrayEncoding: ParameterEncoding {
    public static var `default`: CustomJSONArrayEncoding { return CustomJSONArrayEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var mutableRequest = try urlRequest.asURLRequest()
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let jsonObject = parameters?["params"] {
            let jsondata = try? JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions(rawValue: 0))
            if let jsondata = jsondata {
                mutableRequest.httpBody = jsondata
            }
        }
        return mutableRequest
    }
}


open class RestClient: NSObject {
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
    public enum ErrorCode: Int, Error, RawIntValue {
        case ok            = 200
        case badRequest    = 400
        case unauthorized  = 401
        case requestFailed = 402
        case notFound      = 404
        case serverError0  = 500
        case serverError1  = 502
        case serverError2  = 503
        case serverError3  = 504
    }
    
    internal static let fpKeyIdKey: String = "fp-key-id"
    
    fileprivate let defaultHeaders = [
        "Accept": "application/json",
        "X-FitPay-SDK": "iOS-\(FitpaySDKConfiguration.sdkVersion)"
    ]
    
    internal var _session: RestSession
    internal var keyPair: SECP256R1KeyPair = SECP256R1KeyPair()
    
    lazy internal var _manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return SessionManager(configuration: configuration)
    }()
    
    fileprivate var key: EncryptionKey?
    
    internal var secret: Data {
        let secret = self.keyPair.generateSecretForPublicKey(key?.serverPublicKey ?? "")
        if secret == nil || secret?.count == 0 {
            log.warning("Encription secret is empty.")
        }
        return secret ?? Data()
    }
    
    public init(session: RestSession) {
        _session = session;
    }
    
    internal func collectionItems<T>(_ url: String, completion: @escaping (_ resultCollection: ResultCollection<T>?, _ error: Error?) -> Void) -> T? {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<ResultCollection<T>>) in
                DispatchQueue.main.async {
                    if response.result.error != nil {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        completion(nil, error)
                        
                    } else if let resultValue = response.result.value {
                        resultValue.client = self
                        resultValue.applySecret(self.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                        completion(resultValue, response.result.error)
                        
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
        
        return nil
    }
    
    /**
     Completion handler
     
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias DeleteHandler = (_ error: NSError?) -> Void
    
}

// MARK: Confirm package
extension RestClient {
    /**
     Completion handler
     
     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    public typealias ConfirmCommitHandler = (_ error: NSError?) -> Void
    
    open func confirm(_ url: String, executionResult: NonAPDUCommitState, completion: @escaping ConfirmCommitHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            let params = ["result": executionResult.description]
            let request = self._manager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            request.validate().responseString { (response: DataResponse<String>) in
                DispatchQueue.main.async {
                    completion(response.result.error as NSError?)
                }
            }
        }
    }
    
    /**
     Completion handler
     
     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    public typealias ConfirmAPDUPackageHandler = (_ error: NSError?) -> Void
    
    /**
     Endpoint to allow for returning responses to APDU execution
     
     - parameter package:    ApduPackage object
     - parameter completion: ConfirmAPDUPackageHandler closure
     */
    open func confirmAPDUPackage(_ url: String, package: ApduPackage, completion: @escaping ConfirmAPDUPackageHandler) {
        guard package.packageId != nil else {
            completion(NSError.error(code: ErrorCode.badRequest, domain: RestClient.self, message: "packageId should not be nil"))
            return
        }
        
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            let request = self._manager.request(url, method: .post, parameters: package.responseDictionary, encoding: JSONEncoding.default, headers: headers)
            request.validate().responseString { (response: DataResponse<String>) in
                DispatchQueue.main.async {
                    completion(response.result.error as NSError?)
                }
            }
        }
    }
}

// MARK: Transactions
extension RestClient {
    /**
     Completion handler
     
     - parameter transactions: Provides ResultCollection<Transaction> object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    public typealias TransactionsHandler = (_ result: ResultCollection<Transaction>?, _ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter transaction: Provides Transaction object, or nil if error occurs
     - parameter error:       Provides error object, or nil if no error occurs
     */
    public typealias TransactionHandler = (_ transaction: Transaction?, _ error: NSError?) -> Void
    
    
    internal func transactions(_ url: String, limit: Int, offset: Int, completion: @escaping TransactionsHandler) {
        let parameters = ["limit": "\(limit)", "offset": "\(offset)"]
        self.transactions(url, parameters: parameters, completion: completion)
    }
    
    internal func transactions(_ url: String, parameters: [String: Any]?, completion: @escaping TransactionsHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<ResultCollection<Transaction>>) in
                DispatchQueue.main.async {
                    if response.result.error != nil {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        completion(nil, error)
                        
                    } else if let resultValue = response.result.value {
                        resultValue.client = self
                        completion(resultValue, response.result.error as NSError?)
                        
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }

}

// MARK: Encryption
extension RestClient {
    /**
     Completion handler
     
     - parameter encryptionKey?: Provides created EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    internal typealias CreateEncryptionKeyHandler = (_ encryptionKey: EncryptionKey?, _ error: NSError?) -> Void
    
    /**
     Creates a new encryption key pair
     
     - parameter clientPublicKey: client public key
     - parameter completion:      CreateEncryptionKeyHandler closure
     */
    internal func createEncryptionKey(clientPublicKey: String, completion: @escaping CreateEncryptionKeyHandler) {
        let headers = self.defaultHeaders
        let parameters = ["clientPublicKey": clientPublicKey]
        
        let request = _manager.request(self._session.baseAPIURL + "/config/encryptionKeys", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<EncryptionKey>) in
            DispatchQueue.main.async {
                if response.result.error != nil {
                    let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                    completion(nil, error)
                    
                } else if let resultValue = response.result.value {
                    completion(resultValue, response.result.error as NSError?)
                    
                } else {
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
    internal typealias EncryptionKeyHandler = (_ encryptionKey: EncryptionKey?, _ error: NSError?) -> Void
    
    /**
     Retrieve and individual key pair
     
     - parameter keyId:      key id
     - parameter completion: EncryptionKeyHandler closure
     */
    internal func encryptionKey(_ keyId: String, completion: @escaping EncryptionKeyHandler) {
        let headers = self.defaultHeaders
        let request = _manager.request(self._session.baseAPIURL + "/config/encryptionKeys/" + keyId, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<EncryptionKey>) in
            DispatchQueue.main.async {
                if response.result.error != nil {
                    let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                    completion(nil, error)
                    
                } else if let resultValue = response.result.value {
                    completion(resultValue, nil)
                    
                } else {
                    completion(nil, NSError.unhandledError(RestClient.self))
                }
            }
        }
        
    }
    
    /**
     Completion handler
     
     - parameter error?: Provides error object, or nil if no error occurs
     */
    internal typealias DeleteEncryptionKeyHandler = (_ error: Error?) -> Void
    
    /**
     Deletes encryption key
     
     - parameter keyId:      key id
     - parameter completion: DeleteEncryptionKeyHandler
     */
    internal func deleteEncryptionKey(_ keyId: String, completion: @escaping DeleteEncryptionKeyHandler) {
        let headers = self.defaultHeaders
        let request = _manager.request(self._session.baseAPIURL + "/config/encryptionKeys/" + keyId, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseString { (response: DataResponse<String>) in
            DispatchQueue.main.async {
                completion(response.result.error)
            }
        }
    }
    
    typealias CreateKeyIfNeededHandler = CreateEncryptionKeyHandler
    
    internal func createKeyIfNeeded(_ completion: @escaping CreateKeyIfNeededHandler) {
        if let key = self.key, !key.isExpired() {
            completion(key, nil)
        } else {
            self.createEncryptionKey(clientPublicKey: self.keyPair.publicKey!) { [weak self] (encryptionKey, error) in
                if let error = error {
                    completion(nil, error)
                } else if let encryptionKey = encryptionKey {
                    self?.key = encryptionKey
                    completion(self?.key, nil)
                }
            }
        }
    }
}

// MARK: Request Signature Helpers
extension RestClient {
    
    typealias CreateAuthHeaders = (_ headers: [String: String]?, _ error: NSError?) -> Void
    
    internal func createAuthHeaders(_ completion: CreateAuthHeaders) {
        if self._session.isAuthorized {
            completion(self.defaultHeaders + ["Authorization": "Bearer " + self._session.accessToken!], nil)
        } else {
            completion(nil, NSError.error(code: ErrorCode.unauthorized, domain: RestClient.self, message: "\(ErrorCode.unauthorized)"))
        }
    }
    
    internal func skipAuthHeaders(_ completion: CreateAuthHeaders) {
        // do nothing
        completion(self.defaultHeaders, nil)
    }
    
    typealias PrepareAuthAndKeyHeaders = (_ headers: [String: String]?, _ error: NSError?) -> Void
    
    internal func prepareAuthAndKeyHeaders(_ completion: @escaping PrepareAuthAndKeyHeaders) {
        self.createAuthHeaders { [weak self] (headers, error) in
            if let error = error {
                completion(nil, error)
            } else {
                self?.createKeyIfNeeded { (encryptionKey, keyError) in
                    if let keyError = keyError {
                        completion(nil, keyError)
                    } else {
                        completion(headers! + [RestClient.fpKeyIdKey: encryptionKey!.keyId!], nil)
                    }
                }
            }
        }
    }
    
    typealias PrepareKeyHeader = (_ headers: [String: String]?, _ error: NSError?) -> Void
    
    internal func preparKeyHeader(_ completion: @escaping PrepareAuthAndKeyHeaders) {
        self.skipAuthHeaders { [weak self] (headers, error) in
            if let error = error {
                completion(nil, error)
            } else {
                self?.createKeyIfNeeded { (encryptionKey, keyError) in
                    if let keyError = keyError {
                        completion(nil, keyError)
                    } else {
                        completion(headers! + [RestClient.fpKeyIdKey: encryptionKey!.keyId!], nil)
                    }
                }
            }
        }
    }

}

// MARK: Issuers
extension RestClient {
    public typealias IssuersHandler = (_ issuers: Issuers?, _ error: NSError?) -> Void
    
    public func issuers(completion: @escaping IssuersHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = strongSelf._manager.request(strongSelf._session.baseAPIURL + "/issuers",
                                                      method: .get,
                                                      parameters: nil,
                                                      encoding: JSONEncoding.default,
                                                      headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<Issuers>) in
                DispatchQueue.main.async {
                    if let _ = response.result.error {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        completion(nil, error)
                        
                    } else if let resultValue = response.result.value {
                        resultValue.client = self
                        completion(resultValue, response.result.error as NSError?)
                        
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }
}

// MARK: Assets
extension RestClient {
    
    /**
     Completion handler
     
     - parameter asset: Provides Asset object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias AssetsHandler = (_ asset: Asset?, _ error: NSError?) -> Void
    
    internal func assets(_ url: String, completion: @escaping AssetsHandler) {
        let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
        
        DispatchQueue.global().async {
            request.responseData { (response: DataResponse<Data>) in
                if response.result.error != nil {
                    let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                    
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                } else if let resultValue = response.result.value {
                    var asset: Asset?
                    if let image = UIImage(data: resultValue) {
                        asset = Asset(image: image)
                    } else if let string = resultValue.UTF8String {
                        asset = Asset(text: string)
                    } else {
                        asset = Asset(data: resultValue)
                    }
                    
                    DispatchQueue.main.async {
                        completion(asset, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }

}

// MARK: Sync Statistics
extension RestClient {
    /**
     Completion handler
     
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias SyncHandler = (_ error: NSError?) -> Void
    
    internal func makePostCall(_ url: String, parameters: [String: Any]?, completion: @escaping SyncHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            let request = self?._manager.request(url, method: .post, parameters: parameters, encoding: CustomJSONArrayEncoding.default, headers: headers)
            DispatchQueue.global().async {
                request?.response { (response: DefaultDataResponse) in
                    if response.error != nil {
                        DispatchQueue.main.async {
                            completion(response.error as NSError?)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            }
        }
    }

}


/**
 Retrieve an individual asset (i.e. terms and conditions)
 
 - parameter completion:  AssetsHandler closure
 */
public protocol AssetRetrivable {
    func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler)
}

public protocol AssetWithOptionsRerivable {
    func retrieveAssetWith(options: [AssetOption], completion: @escaping RestClient.AssetsHandler)
}


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
