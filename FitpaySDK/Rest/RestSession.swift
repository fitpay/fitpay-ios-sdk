
import Foundation
import AlamofireObjectMapper
import Alamofire
import ObjectMapper
import JWTDecode

public enum AuthScope : String
{
    case userRead =  "user.read"
    case userWrite = "user.write"
    case tokenRead = "token.read"
    case tokenWrite = "token.write"
}

class StringToUrl : URLConvertible {
    let str : String
    init(str: String) {
        self.str = str
    }
    /// Returns a URL that conforms to RFC 2396 or throws an `Error`.
    ///
    /// - throws: An `Error` if the type cannot be converted to a `URL`.
    ///
    /// - returns: A URL or throws an `Error`.
    func asURL() throws -> URL {
        return URL(string: str)!
    }
}

internal class AuthorizationDetails : Mappable
{
    var tokenType:String?
    var accessToken:String?
    var expiresIn:String?
    var scope:String?
    var jti:String?

    required init?(_ map: Map)
    {
        
    }
    
    func mapping(_ map: Map)
    {
        tokenType <- map["token_type"]
        accessToken <- map["access_token"]
        expiresIn <- map["expires_in"]
        scope <- map["scope"]
        jti <- map["jti"]
    }
}

open class RestSession : NSObject
{
    public enum ErrorEnum : Int, Error, RawIntValue
    {
        case decodeFailure = 1000
        case parsingFailure
        case accessTokenFailure
    }

    fileprivate var clientId:String
    fileprivate var redirectUri:String

    open var userId:String?
    internal var accessToken:String?
    open var isAuthorized:Bool
    {
        return self.accessToken != nil
    }
    
    open func setWebViewAuthorization(_ webViewSessionData:WebViewSessionData) {
        self.accessToken = webViewSessionData.token
        self.userId = webViewSessionData.userId
    }
    
    lazy fileprivate var _manager:SessionManager =
        {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            return SessionManager(configuration: configuration)
    }()
    
    fileprivate (set) internal var baseAPIURL:String
    fileprivate (set) internal var authorizeURL:String

    public init(configuration : FitpaySDKConfiguration = FitpaySDKConfiguration.defaultConfiguration)
    {
        self.clientId = configuration.clientId
        self.redirectUri = configuration.redirectUri
        self.authorizeURL = "\(configuration.baseAuthURL)/oauth/authorize"
        self.baseAPIURL = configuration.baseAPIURL
    }

    public typealias LoginHandler = (_ error:NSError?)->Void

    @objc open func login(username:String, password:String, completion:@escaping LoginHandler)
    {
        self.acquireAccessToken(clientId: self.clientId, redirectUri: self.redirectUri, username: username, password:password, completion:
        {
            (details:AuthorizationDetails?, error:NSError?)->Void in

            DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                () -> Void in

                if let error = error
                {
                    DispatchQueue.main.async(execute: {
                        () -> Void in

                        completion(error)
                    })
                }
                else
                {
                    if let accessToken = details?.accessToken
                    {
                        guard let jwt = try? decode(accessToken) else
                        {
                            DispatchQueue.main.async(execute: {
                                () -> Void in

                                completion(NSError.error(code:Error.decodeFailure, domain:RestSession.self, message: "Failed to decode access token"))
                            })

                            return
                        }

                        if let userId = jwt.body["user_id"] as? String
                        {
                            DispatchQueue.main.async(execute: {
                                [unowned self] () -> Void in

                                debugPrint("successful login for user: \(userId)")
                                self.userId = userId
                                self.accessToken = accessToken
                                completion(nil)
                            })
                        }
                        else
                        {
                            DispatchQueue.main.async(execute: {
                                () -> Void in

                                completion(NSError.error(code:ErrorEnum.parsingFailure, domain:RestSession.self, message: "Failed to parse user id"))
                            })
                        }
                    }
                    else
                    {
                        DispatchQueue.main.async(execute: {
                            () -> Void in

                            completion(NSError.error(code:ErrorEnum.accessTokenFailure, domain:RestSession.self, message: "Failed to retrieve access token"))
                        })
                    }
                }
            })
        })
    }

    internal typealias AcquireAccessTokenHandler = (AuthorizationDetails?, NSError?)->Void

    internal func acquireAccessToken(clientId:String, redirectUri:String, username:String, password:String, completion:@escaping AcquireAccessTokenHandler)
    {
        let headers = ["Accept" : "application/json"]
        let parameters = [
                "response_type" : "token",
                "client_id" : clientId,
                "redirect_uri" : redirectUri,
                "credentials" : ["username" : username, "password" : password].JSONString!
        ]

        let request = _manager.request(StringToUrl(str: self.authorizeURL), method: HTTPMethod.get, parameters: parameters, encoding:.URL, headers: headers)
    
        request.validate().responseObject(queue: dispatch_get_global_queue( DispatchQueue.GlobalQueuePriority.default, 0))
        {
            (response: Response<AuthorizationDetails, NSError>) -> Void in

            dispatch_async(dispatch_get_main_queue(),
            {
                () -> Void in
                
                if let resultError = response.result.error
                {
                    completion(nil, NSError.errorWithData(code: response.response?.statusCode ?? 0, domain: RestSession.self, data: response.data, alternativeError: resultError))
                }
                else if let resultValue = response.result.value
                {
                    completion(resultValue, nil)
                }
                else
                {
                    completion(nil, NSError.unhandledError(RestClient.self))
                }
            })
        }
    }
}
