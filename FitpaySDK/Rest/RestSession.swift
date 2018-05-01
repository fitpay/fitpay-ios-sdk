import Foundation
import AlamofireObjectMapper
import Alamofire
import ObjectMapper
import JWTDecode

public enum AuthScope: String {
    case userRead   = "user.read"
    case userWrite  = "user.write"
    case tokenRead  = "token.read"
    case tokenWrite = "token.write"
}

internal class AuthorizationDetails: Mappable {
    var tokenType: String?
    var accessToken: String?
    var expiresIn: String?
    var scope: String?
    var jti: String?

    required init?(map: Map){
    }

    func mapping(map: Map) {
        tokenType <- map["token_type"]
        accessToken <- map["access_token"]
        expiresIn <- map["expires_in"]
        scope <- map["scope"]
        jti <- map["jti"]
    }
}

@objcMembers
open class RestSession: NSObject {
    public enum ErrorEnum: Int, Error, RawIntValue {
        case decodeFailure = 1000
        case parsingFailure
        case accessTokenFailure
    }

    private(set) var clientId: String
    private(set) var redirectUri: String

    open var userId: String?
    open var accessToken: String?
    open var isAuthorized: Bool {
        return self.accessToken != nil
    }

    open func setWebViewAuthorization(_ webViewSessionData: SessionData) {
        self.accessToken = webViewSessionData.token
        self.userId = webViewSessionData.userId
    }

    lazy private var _manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return SessionManager(configuration: configuration)
    }()

    private(set) internal var baseAPIURL: String
    private(set) internal var authorizeURL: String

    public init(configuration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration, sessionData: SessionData? = nil) {
        self.clientId = configuration.clientId
        self.redirectUri = configuration.redirectUri
        self.authorizeURL = "\(configuration.baseAuthURL)/oauth/authorize"
        self.baseAPIURL = configuration.baseAPIURL
        
        if let sessionData = sessionData {
            self.accessToken = sessionData.token
            self.userId = sessionData.userId
        }
    }

    public typealias LoginHandler = (_ error: NSError?) -> Void
    
    @objc open func login(username: String, password: String, completion: @escaping LoginHandler) {
        self.acquireAccessToken(clientId: self.clientId, redirectUri: self.redirectUri, username: username, password: password, completion: {
            (details: AuthorizationDetails?, error: NSError?) in

            DispatchQueue.global().async {
                if let error = error {
                    completion(error)
                } else {
                    if let accessToken = details?.accessToken {
                        guard let jwt = try? decode(jwt: accessToken) else {
                            completion(NSError.error(code: ErrorEnum.decodeFailure, domain: RestSession.self, message: "Failed to decode access token"))
                            return
                        }

                        if let userId = jwt.body["user_id"] as? String {
                            DispatchQueue.main.async { [weak self] in
                                log.verbose("successful login for user: \(userId)")
                                self?.userId = userId
                                self?.accessToken = accessToken
                                completion(nil)
                            }
                        } else {
                            completion(NSError.error(code: ErrorEnum.parsingFailure, domain: RestSession.self, message: "Failed to parse user id"))
                        }
                    } else {
                        completion(NSError.error(code: ErrorEnum.accessTokenFailure, domain: RestSession.self, message: "Failed to retrieve access token"))
                    }
                }
            }
        })
    }

    internal typealias AcquireAccessTokenHandler = (AuthorizationDetails?, NSError?) -> Void

    internal func acquireAccessToken(clientId: String, redirectUri: String, username: String, password: String, completion: @escaping AcquireAccessTokenHandler) {
        let headers = ["Accept": "application/json"]
        let parameters = [
            "response_type": "token",
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "credentials": ["username": username, "password": password].JSONString!
        ]

        let request = _manager.request(self.authorizeURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers)
        request.validate().responseObject(queue: DispatchQueue.global()) {
            (response: DataResponse<AuthorizationDetails>) in

            DispatchQueue.main.async {
                if let resultError = response.result.error {
                    completion(nil, NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestSession.self, data: response.data, alternativeError: resultError as NSError?))
                } else if let resultValue = response.result.value {
                    completion(resultValue, nil)
                } else {
                    completion(nil, NSError.unhandledError(RestClient.self))
                }
            }
        }
    }
}

extension RestSession {
    public enum ErrorCode : Int, Error, RawIntValue, CustomStringConvertible
    {
        case unknownError                   = 0
        case deviceNotFound                 = 10001
        case userOrDeviceEmpty				= 10002
        
        public var description : String {
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
    
    public typealias GetUserAndDeviceCompletion = (User?, DeviceInfo?, NSError?) -> Void

    class func GetUserAndDeviceWith(sessionData: SessionData,
                                    sdkConfiguration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration,
                                    completion: @escaping GetUserAndDeviceCompletion) -> RestClient? {
        guard let userId = sessionData.userId, let deviceId = sessionData.deviceId else {
            completion(nil, nil, NSError.error(code: RestSession.ErrorCode.userOrDeviceEmpty, domain: RestSession.self))
            return nil
        }
        
        let session = RestSession(configuration: sdkConfiguration, sessionData: sessionData)
        let client = RestClient(session: session)
        
        
        client.user(id: userId) { (user, error) in

            guard user != nil && error == nil else {
                completion(nil, nil, error)
                return
            }
            
            user?.listDevices(limit: 20, offset: 0, completion: { (devicesColletion, error) in
                guard user != nil && error == nil else {
                    completion(nil, nil, error)
                    return
                }
                
                for device in devicesColletion!.results! {
                    if device.deviceIdentifier == deviceId {
                        completion(user!, device, nil)
                        return
                    }
                }
                
                devicesColletion?.collectAllAvailable({ (devices, error) in
                    guard error == nil, let devices = devices else {
                        completion(nil, nil, error as NSError?)
                        return
                    }
                    
                    for device in devices {
                        if device.deviceIdentifier == deviceId {
                            completion(user!, device, nil)
                            return
                        }
                    }
                    
                    completion(nil, nil, NSError.error(code: RestSession.ErrorCode.deviceNotFound, domain: RestSession.self))
                })
            })
        }
        
        return client
    }
    
    class func GetUserAndDeviceWith(token: String,
                                    userId: String,
                                    deviceId: String,
                                    sdkConfiguration: FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration,
                                    completion: @escaping GetUserAndDeviceCompletion) -> RestClient? {
        return RestSession.GetUserAndDeviceWith(sessionData: SessionData(token: token, userId: userId, deviceId: deviceId),
                                                sdkConfiguration: sdkConfiguration,
                                                completion: completion)
    }

}

