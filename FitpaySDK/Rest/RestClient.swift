
import Foundation
import Alamofire

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
    
    static let fpKeyIdKey: String = "fp-key-id"
    
    private let defaultHeaders = [
        "Accept": "application/json",
        "X-FitPay-SDK": "iOS-\(FitpayConfig.sdkVersion)"
    ]
    
    var _session: RestSession
    var keyPair: SECP256R1KeyPair = SECP256R1KeyPair()
    
    lazy var _manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return SessionManager(configuration: configuration)
    }()
    
    var key: EncryptionKey?
    
    var secret: Data {
        let secret = self.keyPair.generateSecretForPublicKey(key?.serverPublicKey ?? "")
        if secret == nil || secret?.count == 0 {
            log.warning("Encription secret is empty.")
        }
        return secret ?? Data()
    }
    
    public init(session: RestSession) {
        _session = session;
    }
    
    func collectionItems<T>(_ url: String, completion: @escaping (_ resultCollection: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) -> T? {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = self?._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            self?.makeRequest(request: request) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                guard let strongSelf = self else { return }
                let result = try? ResultCollection<T>(resultValue)
                result?.client = self
                result?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(result, nil)
            }
        }
        
        return nil
    }
    
    /**
     Completion handler
     
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias DeleteHandler = (_ error: ErrorResponse?) -> Void
    
}

// MARK: - Confirm package

extension RestClient {
    /**
     Completion handler
     
     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    public typealias ConfirmCommitHandler = (_ error: ErrorResponse?) -> Void
    
    public func confirm(_ url: String, executionResult: NonAPDUCommitState, completion: @escaping ConfirmCommitHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            let params = ["result": executionResult.description]
            let request = self._manager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            self.makeRequest(request: request) { (resultValue, error) in
                completion(error)
            }
        }
    }
    
    /**
     Completion handler
     
     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    public typealias ConfirmAPDUPackageHandler = (_ error: ErrorResponse?) -> Void
    
    /**
     Endpoint to allow for returning responses to APDU execution
     
     - parameter package:    ApduPackage object
     - parameter completion: ConfirmAPDUPackageHandler closure
     */
    public func confirmAPDUPackage(_ url: String, package: ApduPackage, completion: @escaping ConfirmAPDUPackageHandler) {
        guard package.packageId != nil else {
            completion(ErrorResponse(domain: RestClient.self, errorCode: ErrorCode.badRequest.rawValue, errorMessage: "packageId should not be nil"))
            return
        }
        
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            let request = self._manager.request(url, method: .post, parameters: package.responseDictionary, encoding: JSONEncoding.default, headers: headers)
            self.makeRequest(request: request) { (resultValue, error) in
                completion(error)
            }
        }
    }
}

// MARK: - Transactions

extension RestClient {
    /**
     Completion handler
     
     - parameter transactions: Provides ResultCollection<Transaction> object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    public typealias TransactionsHandler = (_ result: ResultCollection<Transaction>?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter transaction: Provides Transaction object, or nil if error occurs
     - parameter error:       Provides error object, or nil if no error occurs
     */
    public typealias TransactionHandler = (_ transaction: Transaction?, _ error: ErrorResponse?) -> Void
    
    
    func transactions(_ url: String, limit: Int, offset: Int, completion: @escaping TransactionsHandler) {
        let parameters = ["limit": "\(limit)", "offset": "\(offset)"]
        self.transactions(url, parameters: parameters, completion: completion)
    }
    
    func transactions(_ url: String, parameters: [String: Any]?, completion: @escaping TransactionsHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = self._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            self.makeRequest(request: request) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let transaction = try? ResultCollection<Transaction>(resultValue)
                transaction?.client = self
                completion(transaction, error)
            }
        }
    }
    
}

// MARK: - Encryption

extension RestClient {
    /**
     Completion handler
     
     - parameter encryptionKey?: Provides created EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    typealias CreateEncryptionKeyHandler = (_ encryptionKey: EncryptionKey?, _ error: ErrorResponse?) -> Void
    
    /**
     Creates a new encryption key pair
     
     - parameter clientPublicKey: client public key
     - parameter completion:      CreateEncryptionKeyHandler closure
     */
    func createEncryptionKey(clientPublicKey: String, completion: @escaping CreateEncryptionKeyHandler) {
        let headers = self.defaultHeaders
        let parameters = ["clientPublicKey": clientPublicKey]
        
        let request = _manager.request(FitpayConfig.apiURL + "/config/encryptionKeys", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        self.makeRequest(request: request) { (resultValue, error) in
            guard let resultValue = resultValue else {
                completion(nil, error)
                return
            }
            completion(try? EncryptionKey(resultValue), error)
        }
    }
    
    /**
     Completion handler
     
     - parameter encryptionKey?: Provides EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    typealias EncryptionKeyHandler = (_ encryptionKey: EncryptionKey?, _ error: ErrorResponse?) -> Void
    
    /**
     Retrieve and individual key pair
     
     - parameter keyId:      key id
     - parameter completion: EncryptionKeyHandler closure
     */
    func encryptionKey(_ keyId: String, completion: @escaping EncryptionKeyHandler) {
        let headers = self.defaultHeaders
        let request = _manager.request(FitpayConfig.apiURL + "/config/encryptionKeys/" + keyId, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        self.makeRequest(request: request) { (resultValue, error) in
            guard let resultValue = resultValue else {
                completion(nil, error)
                return
            }
            completion(try? EncryptionKey(resultValue), error)
        }
    }
    
    /**
     Completion handler
     
     - parameter error?: Provides error object, or nil if no error occurs
     */
    typealias DeleteEncryptionKeyHandler = (_ error: Error?) -> Void
    
    /**
     Deletes encryption key
     
     - parameter keyId:      key id
     - parameter completion: DeleteEncryptionKeyHandler
     */
    func deleteEncryptionKey(_ keyId: String, completion: @escaping DeleteEncryptionKeyHandler) {
        let headers = self.defaultHeaders
        let request = _manager.request(FitpayConfig.apiURL + "/config/encryptionKeys/" + keyId, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        request.validate().responseString { (response: DataResponse<String>) in
            DispatchQueue.main.async {
                completion(response.result.error)
            }
        }
    }
    
    typealias CreateKeyIfNeededHandler = CreateEncryptionKeyHandler
    
    func createKeyIfNeeded(_ completion: @escaping CreateKeyIfNeededHandler) {
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
    
    typealias CreateAuthHeaders = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void
    
    func createAuthHeaders(_ completion: CreateAuthHeaders) {
        if self._session.isAuthorized {
            completion(self.defaultHeaders + ["Authorization": "Bearer " + self._session.accessToken!], nil)
        } else {
            completion(nil, ErrorResponse(domain: RestClient.self, errorCode: ErrorCode.unauthorized.rawValue, errorMessage: "\(ErrorCode.unauthorized)"))
        }
    }
    
    func skipAuthHeaders(_ completion: CreateAuthHeaders) {
        // do nothing
        completion(self.defaultHeaders, nil)
    }
    
    typealias PrepareAuthAndKeyHeaders = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void
    
    func prepareAuthAndKeyHeaders(_ completion: @escaping PrepareAuthAndKeyHeaders) {
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
    
    typealias PrepareKeyHeader = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void
    
    func preparKeyHeader(_ completion: @escaping PrepareAuthAndKeyHeaders) {
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
    public typealias IssuersHandler = (_ issuers: Issuers?, _ error: ErrorResponse?) -> Void
    
    public func issuers(completion: @escaping IssuersHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = strongSelf._manager.request(FitpayConfig.apiURL + "/issuers",
                                                      method: .get,
                                                      parameters: nil,
                                                      encoding: JSONEncoding.default,
                                                      headers: headers)
            self?.makeRequest(request: request) { (resultValue, error) in                
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let issuers = try? Issuers(resultValue)
                issuers?.client = self
                completion(issuers, error)
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
    public typealias AssetsHandler = (_ asset: Asset?, _ error: ErrorResponse?) -> Void
    
    func assets(_ url: String, completion: @escaping AssetsHandler) {
        let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
        
        DispatchQueue.global().async {
            request.responseData { (response: DataResponse<Data>) in
                if response.result.error != nil {
                    let error = try? ErrorResponse(response.data)
                    
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
                        completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
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
    public typealias SyncHandler = (_ error: ErrorResponse?) -> Void
    
    func makePostCall(_ url: String, parameters: [String: Any]?, completion: @escaping SyncHandler) {
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
                            if let _ = response.error {
                                let error = try? ErrorResponse(response.data)
                                completion(error)
                            }
                            else {
                                completion(nil)
                            }
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

// MARK: Reset Device Tasks
extension RestClient {

    /**
     Completion handler

     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias ResetHandler = (_ resetDeviceTask: ResetDeviceResult?, _ error: NSError?) -> Void
    
    /**
     Creates a request for resetting a device

     - parameter deviceId:  device id
     - parameter userId: user id
     - parameter completion:      ResetHandler closure
     */
    func resetDeviceTasks(_ resetUrl: URL, completion: @escaping ResetHandler) {
        self.prepareAuthAndKeyHeaders { [unowned self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
                return
            }
            let request = self._manager.request(resetUrl, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers)
            request.validate().responseJSON { (response) in
                DispatchQueue.main.async {
                    if response.result.error != nil {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        completion(nil, error)
                    } else if let resultValue = response.result.value {
                        completion(try? ResetDeviceResult(resultValue), nil)
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }

    /**
     Creates a request for getting reset status

     - parameter resetId:  reset device task id
     - parameter completion:   ResetHandler closure
     */
    func resetDeviceStatus(_ resetUrl: URL, completion: @escaping ResetHandler) {
        self.prepareAuthAndKeyHeaders { [unowned self] (headers, error) in
            if let headers = headers {
                let request = self._manager.request(resetUrl, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request.validate().responseJSON { (response) in
                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                             completion(try? ResetDeviceResult(resultValue), nil)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }

}

extension RestClient {
    /**
     Completion handler
     
     - parameter resultValue: Provides request object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias RequestHandler = (_ resultValue: Any?, _ error: ErrorResponse?) -> Void
    
    func makeRequest(request: DataRequest?, completion: @escaping RequestHandler) {
        request?.validate().responseJSON(queue: DispatchQueue.global()) { (response) in
            
            DispatchQueue.main.async {
                if response.result.error != nil && response.response?.statusCode != 202 {
                    let JSON = response.data!.UTF8String
                    var error = try? ErrorResponse(JSON)
                    if error == nil {
                        error = ErrorResponse(domain: RestClient.self, errorCode: response.response?.statusCode ?? 0 , errorMessage: response.result.error?.localizedDescription)
                    }
                    completion(nil, error)
                    
                } else if let resultValue = response.result.value {
                    completion(resultValue, nil)
                } else if response.response?.statusCode == 202 {
                    completion(nil, nil)
                } else {
                    completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
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

