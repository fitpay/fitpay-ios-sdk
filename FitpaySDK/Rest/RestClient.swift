import Foundation
import Alamofire

open class RestClient: NSObject {
    
    typealias ResultCollectionHandler<T: Codable> = (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void
    typealias RequestHandler = (_ resultValue: Any?, _ error: ErrorResponse?) -> Void

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
    
    var session: RestSession
    var keyPair: SECP256R1KeyPair = SECP256R1KeyPair()
    
    var key: EncryptionKey?
    
    var secret: Data {
        let secret = self.keyPair.generateSecretForPublicKey(key?.serverPublicKey ?? "")
        if secret == nil || secret?.count == 0 {
            log.warning("REST_CLIENT: Encription secret is empty.")
        }
        return secret ?? Data()
    }
    
    var restRequest: RestRequestable = RestRequest()
    
    /**
     Completion handler
     
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias DeleteHandler = (_ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    public typealias ConfirmHandler = (_ error: ErrorResponse?) -> Void
    
    // MARK: - Lifecycle
    
    public init(session: RestSession, restRequest: RestRequestable? = nil) {
        self.session = session
        
        if let restRequest = restRequest {
            self.restRequest = restRequest
        }
    }
    
    // MARK: - Public Functions
    
    public func confirm(_ url: String, executionResult: NonAPDUCommitState, completion: @escaping ConfirmHandler) {
        let params = ["result": executionResult.description]
        makePostCall(url, parameters: params, completion: completion)
    }
    
    public func acknowledge(_ url: String, completion: @escaping ConfirmHandler) {
        makePostCall(url, parameters: nil, completion: completion)
    }
    
    public func getPlatformConfig(completion: @escaping (_ platform: PlatformConfig?, _ error: ErrorResponse?) -> Void) {
        restRequest.makeRequest(url: FitpayConfig.apiURL + "/mobile/config", method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil) { (resultValue, error) in
            guard let resultValue = resultValue as? [String: Any] else {
                completion(nil, error)
                return
            }

            let config = try? PlatformConfig(resultValue["ios"])
            completion(config, error)
        }
    }
    
    public func getCountries(completion: @escaping (_ countries: CountryCollection?, _ error: ErrorResponse?) -> Void) {
        let url = FitpayConfig.apiURL + "/iso/countries"
        restRequest.makeRequest(url: url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil) { (resultValue, error) in
            guard let resultValue = resultValue as? [String: Any] else {
                completion(nil, error)
                return
            }
            
            let countryCollection = try? CountryCollection(["countries": resultValue])
            countryCollection?.client = self
            completion(countryCollection, error)
        }
    }
    
    // MARK: - Internal
    
    func collectionItems<T>(_ url: String, completion: @escaping (_ resultCollection: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) -> T? {
        makeGetCall(url, parameters: nil, completion: completion)
        return nil
    }
    
    func makeDeleteCall(_ url: String, completion: @escaping DeleteHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers) { (_, error) in
                completion(error)
            }
        }
    }

    func makeGetCall<T: Codable>(_ url: String, limit: Int, offset: Int, overrideHeaders: [String: String]? = nil, completion: @escaping ResultCollectionHandler<T>) {
        let parameters = ["limit": "\(limit)", "offset": "\(offset)"]
        makeGetCall(url, parameters: parameters, overrideHeaders: overrideHeaders, completion: completion)
    }
    
    func makeGetCall<T: Serializable>(_ url: String, parameters: [String: Any]?, overrideHeaders: [String: String]? = nil, completion: @escaping (T?, ErrorResponse?) -> Void) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard var headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            if let overrideHeaders = overrideHeaders {
                for key in overrideHeaders.keys {
                    headers[key] = overrideHeaders[key]
                }
            }
            
            self?.restRequest.makeRequest(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                
                let result = try? T(resultValue)
                (result as? ClientModel)?.client = self
                (result as? SecretApplyable)?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                
                completion(result, error)
            }
        }
    }
    
    func makePostCall(_ url: String, parameters: [String: Any]?, completion: @escaping ConfirmHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { (_, error) in
                completion(error)
            }
        }
    }
    
    func makePostCall<T: Serializable>(_ url: String, parameters: [String: Any]?, completion: @escaping (T?, ErrorResponse?) -> Void) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                
                let result = try? T(resultValue)
                (result as? ClientModel)?.client = self
                (result as? SecretApplyable)?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                
                completion(result, error)
            }
        }
    }
    
    func makePatchCall<T: Serializable>(_ url: String, parameters: [String: Any]?, encoding: ParameterEncoding, completion: @escaping (T?, ErrorResponse?) -> Void) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .patch, parameters: parameters, encoding: encoding, headers: headers) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                
                let result = try? T(resultValue)
                (result as? ClientModel)?.client = self
                (result as? SecretApplyable)?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                
                completion(result, error)
            }
        }
    }
    
}

// MARK: - Confirm package

extension RestClient {
    
    /**
     Endpoint to allow for returning responses to APDU execution
     
     - parameter package:    ApduPackage object
     - parameter completion: ConfirmAPDUPackageHandler closure
     */
    public func confirmAPDUPackage(_ url: String, package: ApduPackage, completion: @escaping ConfirmHandler) {
        guard package.packageId != nil else {
            completion(ErrorResponse(domain: RestClient.self, errorCode: ErrorCode.badRequest.rawValue, errorMessage: "packageId should not be nil"))
            return
        }
        
        makePostCall(url, parameters: package.responseDictionary, completion: completion)
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

}

// MARK: - Encryption

extension RestClient {
    
    /**
     Creates a new encryption key pair
     
     - parameter clientPublicKey: client public key
     - parameter completion:      CreateEncryptionKeyHandler closure
     */
    func createEncryptionKey(clientPublicKey: String, completion: @escaping EncryptionKeyHandler) {
        let parameters = ["clientPublicKey": clientPublicKey]
        
        restRequest.makeRequest(url: FitpayConfig.apiURL + "/config/encryptionKeys", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: session.defaultHeaders) { (resultValue, error) in
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
        restRequest.makeRequest(url: FitpayConfig.apiURL + "/config/encryptionKeys/" + keyId, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: session.defaultHeaders) { (resultValue, error) in
            guard let resultValue = resultValue else {
                completion(nil, error)
                return
            }
            completion(try? EncryptionKey(resultValue), error)
        }
    }
   
    func createKeyIfNeeded(_ completion: @escaping EncryptionKeyHandler) {
        if let key = key, !key.isExpired {
            completion(key, nil)
        } else {
            createEncryptionKey(clientPublicKey: keyPair.publicKey!) { [weak self] (encryptionKey, error) in
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

// MARK: - Request Signature Helpers

extension RestClient {
    
    typealias AuthHeaderHandler = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void
    
    func createAuthHeaders(_ completion: AuthHeaderHandler) {
        if session.isAuthorized {
            completion(session.defaultHeaders + ["Authorization": "Bearer " + session.accessToken!], nil)
        } else {
            completion(nil, ErrorResponse(domain: RestClient.self, errorCode: ErrorCode.unauthorized.rawValue, errorMessage: "\(ErrorCode.unauthorized)"))
        }
    }
    
    func prepareAuthAndKeyHeaders(_ completion: @escaping AuthHeaderHandler) {
        createAuthHeaders { [weak self] (headers, error) in
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
    
    func preparKeyHeader(_ completion: @escaping AuthHeaderHandler) {
        createKeyIfNeeded { (encryptionKey, keyError) in
            if let keyError = keyError {
                completion(nil, keyError)
            } else {
                completion(self.session.defaultHeaders + [RestClient.fpKeyIdKey: encryptionKey!.keyId!], nil)
            }
        }
    }
    
}

// MARK: - Issuers

extension RestClient {
    
    public typealias IssuersHandler = (_ issuers: Issuers?, _ error: ErrorResponse?) -> Void
    
    public func issuers(completion: @escaping IssuersHandler) {
        makeGetCall(FitpayConfig.apiURL + "/issuers", parameters: nil, completion: completion)
    }

}

// MARK: - Assets

extension RestClient {
    
    /**
     Completion handler
     
     - parameter asset: Provides Asset object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias AssetsHandler = (_ asset: Asset?, _ error: ErrorResponse?) -> Void
    
    func assets(_ url: String, completion: @escaping AssetsHandler) {
        restRequest.makeDataRequest(url: url) { (resultValue, error) in
            guard let resultValue = resultValue as? Data else {
                completion(nil, error)
                return
            }
            
            var asset: Asset?
            if let image = UIImage(data: resultValue) {
                asset = Asset(image: image)
            } else if let string = resultValue.UTF8String {
                asset = Asset(text: string)
            } else {
                asset = Asset(data: resultValue)
            }
            
            completion(asset, nil)
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
