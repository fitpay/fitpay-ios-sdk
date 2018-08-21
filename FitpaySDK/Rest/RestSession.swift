import Foundation
import Alamofire

@objcMembers open class RestSession: NSObject {
    
    open var userId: String?
    open var accessToken: String?
    
    open var isAuthorized: Bool {
        return self.accessToken != nil
    }
    
    private var restRequest: RestRequestable = RestRequest()
    
    private typealias AcquireAccessTokenHandler = (AuthorizationDetails?, NSError?) -> Void

    // MARK: - Lifecycle
    
    public init(sessionData: SessionData? = nil, restRequest: RestRequestable? = nil) {
        if let sessionData = sessionData {
            self.accessToken = sessionData.token
            self.userId = sessionData.userId
        }
        
        if let restRequest = restRequest {
            self.restRequest = restRequest
        }
    }
    
    // MARK: - Public Functions
    
    @objc open func setWebViewAuthorization(_ webViewSessionData: SessionData) {
        self.accessToken = webViewSessionData.token
        self.userId = webViewSessionData.userId
    }
    
    @objc open func login(username: String, password: String, completion: @escaping (_ error: NSError?) -> Void) {
        self.acquireAccessToken(username: username, password: password) { (details, error) in
            if let error = error {
                completion(error)
            } else {
                self.setIdAndToken(details: details, completion: completion)
            }
        }
    }
    
    @objc open func login(firebaseToken: String, completion: @escaping (_ error: NSError?) -> Void) {
        acquireAccessToken(firebaseToken: firebaseToken) { (details, error) in
            if let error = error {
                completion(error)
            } else {
                self.setIdAndToken(details: details, completion: completion)
            }
        }
    }
    
    // MARK: - Private Functions
    
    private func acquireAccessToken(username: String, password: String, completion: @escaping AcquireAccessTokenHandler) {
        let headers = ["Accept": "application/json"]
        let parameters: [String: String] = [
            "response_type": "token",
            "client_id": FitpayConfig.clientId,
            "redirect_uri": FitpayConfig.redirectURL,
            "credentials": ["username": username, "password": password].JSONString!
        ]

        restRequest.makeRequest(url: FitpayConfig.authURL + "/oauth/authorize", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers) { (resultValue, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            let authorizationDetails = try? AuthorizationDetails(resultValue)
            completion(authorizationDetails, nil)
        }
    }
    
    private func acquireAccessToken(firebaseToken: String, completion: @escaping AcquireAccessTokenHandler) {
        let headers = ["Accept": "application/json"]
        let parameters: [String: String] = [
            "response_type": "token",
            "client_id": FitpayConfig.clientId,
            "redirect_uri": FitpayConfig.redirectURL,
            "firebase_token": firebaseToken
        ]
        
        restRequest.makeRequest(url: FitpayConfig.authURL + "/oauth/token", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers) { (resultValue, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            let authorizationDetails = try? AuthorizationDetails(resultValue)
            completion(authorizationDetails, nil)
        }
    }

    private func setIdAndToken(details: AuthorizationDetails?, completion: @escaping (_ error: NSError?) -> Void) {
        guard let accessToken = details?.accessToken else {
            completion(NSError.error(code: ErrorEnum.accessTokenFailure, domain: RestSession.self, message: "Failed to retrieve access token"))
            return
        }
        guard let jwt = try? JWS(token: accessToken) else {
            completion(NSError.error(code: ErrorEnum.decodeFailure, domain: RestSession.self, message: "Failed to decode access token"))
            return
        }
        guard let userId = jwt.body["user_id"] as? String else {
            completion(NSError.error(code: ErrorEnum.parsingFailure, domain: RestSession.self, message: "Failed to parse user id"))
            return
        }
        
        log.verbose("REST_SESSION: successfully acquired token for user: \(userId)")
        self.userId = userId
        self.accessToken = accessToken
        completion(nil)
    }
}

extension RestSession {
    
    public typealias GetUserAndDeviceCompletion = (User?, Device?, ErrorResponse?) -> Void
    
    class func GetUserAndDeviceWith(sessionData: SessionData, completion: @escaping GetUserAndDeviceCompletion) -> RestClient? {
        guard let userId = sessionData.userId, let deviceId = sessionData.deviceId else {
            completion(nil, nil, ErrorResponse(domain: RestSession.self, errorCode: RestSession.ErrorCode.userOrDeviceEmpty.rawValue, errorMessage: ""))
            return nil
        }
        
        let session = RestSession(sessionData: sessionData)
        let client = RestClient(session: session)
        
        client.user(id: userId) { (user, error) in
            guard user != nil && error == nil else {
                completion(nil, nil, error)
                return
            }
            
            user?.getDevices(limit: 20, offset: 0) { (devicesCollection, error) in
                guard user != nil && error == nil else {
                    completion(nil, nil, error)
                    return
                }
                
                if let device = devicesCollection?.results?.first(where: { $0.deviceIdentifier == deviceId }) {
                    completion(user!, device, nil)
                    return
                }
                
                devicesCollection?.collectAllAvailable { (devices, error) in
                    guard error == nil, let devices = devices else {
                        completion(nil, nil, error)
                        return
                    }
                    
                    if let device = devices.first(where: { $0.deviceIdentifier == deviceId }) {
                        completion(user!, device, nil)
                        return
                    }
                    
                    completion(nil, nil, ErrorResponse(domain: RestSession.self, errorCode: RestSession.ErrorCode.deviceNotFound.rawValue, errorMessage: ""))
                }
            }
        }
        
        return client
    }
    
    class func GetUserAndDeviceWith(token: String, userId: String, deviceId: String, completion: @escaping GetUserAndDeviceCompletion) -> RestClient? {
        return RestSession.GetUserAndDeviceWith(sessionData: SessionData(token: token, userId: userId, deviceId: deviceId), completion: completion)
    }
    
}

// MARK: - Nested Objects

extension RestSession {
    
    public enum ErrorEnum: Int, Error, RawIntValue {
        case decodeFailure = 1000
        case parsingFailure
        case accessTokenFailure
    }
    
    public enum ErrorCode: Int, Error, RawIntValue, CustomStringConvertible {
        case unknownError       = 0
        case deviceNotFound     = 10001
        case userOrDeviceEmpty  = 10002
        
        public var description: String {
            switch self {
            case .unknownError:
                return "Unknown error"
            case .deviceNotFound:
                return "Can't find device provided by wv."
            case .userOrDeviceEmpty:
                return "User or device empty."
            }
        }
    }
    
    struct AuthorizationDetails: Serializable {
        var tokenType: String?
        var accessToken: String?
        var expiresIn: String?
        var scope: String?
        var jti: String?
        
        private enum CodingKeys: String, CodingKey {
            case tokenType = "token_type"
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case scope
            case jti
        }
    }
    
}



