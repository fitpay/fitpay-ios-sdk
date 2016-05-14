
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
    
    func mapping(map: Map)
    {
        tokenType <- map["token_type"]
        accessToken <- map["access_token"]
        expiresIn <- map["expires_in"]
        scope <- map["scope"]
        jti <- map["jti"]
    }
}

public class RestSession : NSObject
{
    public enum Error : Int, ErrorType, RawIntValue
    {
        case DecodeFailure = 1000
        case ParsingFailure
        case AccessTokenFailure
    }

    private var clientId:String
    private var redirectUri:String

    public var userId:String?
    internal var accessToken:String?
    public var isAuthorized:Bool
    {
        return self.accessToken != nil
    }
    
    public func setWebViewAuthorization(webViewSessionData:WebViewSessionData) {
        self.accessToken = webViewSessionData.token
        self.userId = webViewSessionData.userId
    }
    
    lazy private var manager:Manager =
    {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        return Manager(configuration: configuration)
    }()
    
    private (set) internal var baseAPIURL:String
    private (set) internal var authorizeURL:String

    public init(clientId:String, redirectUri:String, authorizeURL:String, baseAPIURL:String)
    {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.authorizeURL = authorizeURL
        self.baseAPIURL = baseAPIURL
    }

    public typealias LoginHandler = (error:NSError?)->Void

    @objc public func login(username username:String, password:String, completion:LoginHandler)
    {
        self.acquireAccessToken(clientId: self.clientId, redirectUri: self.redirectUri, username: username, password:password, completion:
        {
            (details:AuthorizationDetails?, error:NSError?)->Void in

            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            {
                () -> Void in

                if let error = error
                {
                    dispatch_async(dispatch_get_main_queue(),
                    {
                        () -> Void in

                        completion(error:error)
                    })
                }
                else
                {
                    if let accessToken = details?.accessToken
                    {
                        guard let jwt = try? decode(accessToken) else
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            {
                                () -> Void in

                                completion(error:NSError.error(code:Error.DecodeFailure, domain:RestSession.self, message: "Failed to decode access token"))
                            })

                            return
                        }

                        if let userId = jwt.body["user_id"] as? String
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            {
                                [unowned self] () -> Void in

                                debugPrint("successful login for user: \(userId)")
                                self.userId = userId
                                self.accessToken = accessToken
                                completion(error:nil)
                            })
                        }
                        else
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            {
                                () -> Void in

                                completion(error:NSError.error(code:Error.ParsingFailure, domain:RestSession.self, message: "Failed to parse user id"))
                            })
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(),
                        {
                            () -> Void in

                            completion(error:NSError.error(code:Error.AccessTokenFailure, domain:RestSession.self, message: "Failed to retrieve access token"))
                        })
                    }
                }
            })
        })
    }

    internal typealias AcquireAccessTokenHandler = (AuthorizationDetails?, NSError?)->Void

    internal func acquireAccessToken(clientId clientId:String, redirectUri:String, username:String, password:String, completion:AcquireAccessTokenHandler)
    {
        let headers = ["Accept" : "application/json"]
        let parameters = [
                "response_type" : "token",
                "client_id" : clientId,
                "redirect_uri" : redirectUri,
                "credentials" : ["username" : username, "password" : password].JSONString!
        ]

        let request = manager.request(.POST, self.authorizeURL, parameters: parameters, encoding:.URL, headers: headers)
    
        request.validate().responseObject(queue: dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
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
