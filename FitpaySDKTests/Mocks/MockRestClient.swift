@testable import FitpaySDK
import XCTest

class MockRestClient: NSObject, RestClientInterface {

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

    var _session: MockRestSession
    var keyPair: MockSECP256R1KeyPair = MockSECP256R1KeyPair()

    var key: EncryptionKey?

    var secret: Data {
        let secret = self.keyPair.generateSecretForPublicKey(key?.serverPublicKey ?? "")

        if secret == nil || secret?.count == 0 {
            log.warning("Encription secret is empty.")
        }
        return secret ?? Data()
    }

    public init(session: MockRestSession) {
        _session = session;
    }

     func collectionItems<T>(_ url: String, completion: @escaping (_ resultCollection: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) -> T? {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                guard let strongSelf = self else { return }
                let result = try? ResultCollection<T>(resultValue)
                result?.client = self
                result?.applySecret(strongSelf.secret, expectedKeyId: headers[MockRestClient.fpKeyIdKey])
                completion(result, nil)
            }
        }

        return nil
    }

    public func confirm(_ url: String, executionResult: NonAPDUCommitState, completion: @escaping ConfirmCommitHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(error) }
                return
            }
            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "")
            let request = Request(request: url)
            request.response = response

            self.makeRequest(request: request) { (resultValue, error) in
                completion(error)
            }
        }
    }

}

// MARK: - Confirm package

extension MockRestClient {
    /**
     Endpoint to allow for returning responses to APDU execution

     - parameter package:    ApduPackage object
     - parameter completion: ConfirmAPDUPackageHandler closure
     */
    public func confirmAPDUPackage(_ url: String, package: ApduPackage, completion: @escaping ConfirmAPDUPackageHandler) {
        guard package.packageId != nil else {
            completion(ErrorResponse(domain: MockRestClient.self, errorCode: ErrorCode.badRequest.rawValue, errorMessage: "packageId should not be nil"))
            return
        }

        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "confirmJson")
            let request = Request(request: url)
            request.response = response

            self.makeRequest(request: request) { (resultValue, error) in
                completion(error)
            }
        }
    }
}

// MARK: - Transactions

extension MockRestClient {
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

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "listTransactions")
            let request = Request(request: url)
            request.response = response

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

extension MockRestClient {
    /**
     Creates a new encryption key pair

     - parameter clientPublicKey: client public key
     - parameter completion:      CreateEncryptionKeyHandler closure
     */
    func createEncryptionKey(clientPublicKey: String, completion: @escaping CreateEncryptionKeyHandler) {
        let headers = self.defaultHeaders
        var response = Response()
        let url = FitpayConfig.apiURL + "/config/encryptionKeys"
        response.data = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
        response.json = self.loadDataFromJSONFile(filename: "getEncryptionKeyJson")
        let request = Request(request: url)
        request.response = response
        self.makeRequest(request: request) { (resultValue, error) in
            guard let resultValue = resultValue else {
                completion(nil, error)
                return
            }
            completion(try? EncryptionKey(resultValue), error)
        }
    }

    /**
     Retrieve and individual key pair

     - parameter keyId:      key id
     - parameter completion: EncryptionKeyHandler closure
     */
    func encryptionKey(_ keyId: String, completion: @escaping EncryptionKeyHandler) {
        let headers = self.defaultHeaders
        var response = Response()
        let url = FitpayConfig.apiURL + "/config/encryptionKeys/" + keyId
        response.data = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
        response.json = self.loadDataFromJSONFile(filename: "getEncryptionKeyJson")
        let request = Request(request: url)
        request.response = response
        if keyId == "some_fake_id" {
        response.json = self.loadDataFromJSONFile(filename: "Error")
        request.response.error = ErrorResponse.unhandledError(domain: MockRestClient.self)
        }

        self.makeRequest(request: request) { (resultValue, error) in
            guard let resultValue = resultValue else {
                completion(nil, error)
                return
            }
            completion(try? EncryptionKey(resultValue), error)
        }
    }

    /**
     Deletes encryption key

     - parameter keyId:      key id
     - parameter completion: DeleteEncryptionKeyHandler
     */
    func deleteEncryptionKey(_ keyId: String, completion: @escaping DeleteEncryptionKeyHandler) {
       let headers = self.defaultHeaders
        var response = Response()
        let url = FitpayConfig.apiURL + "/config/encryptionKeys/" + keyId
        response.data = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
        response.json = self.loadDataFromJSONFile(filename: "")
        let request = Request(request: url)
        request.response = response

        self.makeRequest(request: request) { (resultValue, error) in
            completion(error)
        }
    }

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
extension MockRestClient {

    func createAuthHeaders(_ completion: CreateAuthHeaders) {
        if self._session.isAuthorized {
            completion(self.defaultHeaders + ["Authorization": "Bearer " + self._session.accessToken!], nil)
        } else {
            completion(nil, ErrorResponse(domain: MockRestClient.self, errorCode: ErrorCode.unauthorized.rawValue, errorMessage: "\(ErrorCode.unauthorized)"))
        }
    }

    func skipAuthHeaders(_ completion: CreateAuthHeaders) {
        // do nothing
        completion(self.defaultHeaders, nil)
    }

    func prepareAuthAndKeyHeaders(_ completion: @escaping PrepareAuthAndKeyHeaders) {
        self.createAuthHeaders { [weak self] (headers, error) in
            if let error = error {
                completion(nil, error)
            } else {
                self?.createKeyIfNeeded { (encryptionKey, keyError) in
                    if let keyError = keyError {
                        completion(nil, keyError)
                    } else {
                        completion(headers! + [MockRestClient.fpKeyIdKey: encryptionKey!.keyId!], nil)
                    }
                }
            }
        }
    }

    func preparKeyHeader(_ completion: @escaping PrepareAuthAndKeyHeaders) {
        self.skipAuthHeaders { [weak self] (headers, error) in
            if let error = error {
                completion(nil, error)
            } else {
                self?.createKeyIfNeeded { (encryptionKey, keyError) in
                    if let keyError = keyError {
                        completion(nil, keyError)
                    } else {
                        completion(headers! + [MockRestClient.fpKeyIdKey: encryptionKey!.keyId!], nil)
                    }
                }
            }
        }
    }

}

// MARK: Issuers
extension MockRestClient {
     public func issuers(completion: @escaping IssuersHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }

            var response = Response()
            let url = FitpayConfig.apiURL + "/issuers"
            response.data = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "issuers")
            let request = Request(request: url)
            request.response = response
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
extension MockRestClient {
    func assets(_ url: String, completion: @escaping AssetsHandler) {
           let asset = Asset(image: UIImage())
            completion(asset, nil)
        }
}

// MARK: Sync Statistics
extension MockRestClient {
    func makePostCall(_ url: String, parameters: [String: Any]?, completion: @escaping SyncHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
              completion(error)
            }
        }
    }

}

// MARK: Reset Device Tasks
extension MockRestClient {
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
            var response = Response()
            response.data = HTTPURLResponse(url: resetUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "resetDeviceTask")
            let request = Request(request: resetUrl.absoluteString)
            request.response = response
            self.makeRequest(request: request) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let resetDeviceResult = try? ResetDeviceResult(resultValue)

                completion(resetDeviceResult, error)
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
                var response = Response()
                response.data = HTTPURLResponse(url: resetUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
                response.json = self.loadDataFromJSONFile(filename: "resetDeviceTask")
                let request = Request(request: resetUrl.absoluteString)
                request.response = response
                self.makeRequest(request: request) { (resultValue, error) in
                    guard let resultValue = resultValue else {
                        completion(nil, error)
                        return
                    }
                    let resetDeviceResult = try? ResetDeviceResult(resultValue)

                    completion(resetDeviceResult, error)
                }
            }
        }
    }

}

extension MockRestClient {
    func makeRequest(request: Request?, completion: @escaping RequestHandler) {
        request?.responseJSON(){ (request) in

            DispatchQueue.main.async {
                if request.response?.error != nil {
                    let JSON = request.response?.json
                    var error = try? ErrorResponse(JSON)
                    if error == nil {
                        error = ErrorResponse(domain: MockRestClient.self, errorCode: request.response.data?.statusCode ?? 0 , errorMessage: request.response.error?.localizedDescription)
                    }
                    completion(nil, error)

                } else if let resultValue = request.response?.json {
                    completion(resultValue, nil)
                } else {
                    completion(nil, ErrorResponse.unhandledError(domain: MockRestClient.self))
                }
            }
        }
    }

    func loadDataFromJSONFile(filename: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        if let filepath = bundle.path(forResource: filename, ofType: "json") {
            do {
                let contents = try String(contentsOfFile: filepath)
                XCTAssertNotNil(contents)
                return contents
            } catch {
                XCTAssert(false, "Can't read from file")
            }
        } else {
            XCTAssert(false, "File not found")
        }
        return nil
    }
}
