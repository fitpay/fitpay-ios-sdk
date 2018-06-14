import JWTDecode
@testable import FitpaySDK
import XCTest

@objcMembers open class MockRestSession: NSObject {
    public enum ErrorEnum: Int, Error, RawIntValue {
        case decodeFailure = 1000
        case parsingFailure
        case accessTokenFailure
    }

    open var userId: String?
    open var accessToken: String?
    open var isAuthorized: Bool {
        return self.accessToken != nil
    }

    open func setWebViewAuthorization(_ webViewSessionData: SessionData) {
        self.accessToken = webViewSessionData.token
        self.userId = webViewSessionData.userId
    }

    public init(sessionData: SessionData? = nil) {
        if let sessionData = sessionData {
            self.accessToken = sessionData.token
            self.userId = sessionData.userId
        }
    }

    public typealias LoginHandler = (_ error: NSError?) -> Void

    @objc open func login(username: String, password: String, completion: @escaping LoginHandler) {
        self.acquireAccessToken(username: username, password: password) { (details: AuthorizationDetails?, error: NSError?) in

            DispatchQueue.global().async {
                if let error = error {
                    completion(error)
                } else {
                    guard let accessToken = details?.accessToken else {
                        completion(NSError.error(code: ErrorEnum.accessTokenFailure, domain: RestSession.self, message: "Failed to retrieve access token"))
                        return
                    }
                    guard let jwt = try? decode(jwt: accessToken) else {
                        completion(NSError.error(code: ErrorEnum.decodeFailure, domain: RestSession.self, message: "Failed to decode access token"))
                        return
                    }
                    guard let userId = jwt.body["user_id"] as? String else {
                        completion(NSError.error(code: ErrorEnum.parsingFailure, domain: RestSession.self, message: "Failed to parse user id"))
                        return
                    }

                    DispatchQueue.main.async { [weak self] in
                        log.verbose("successful login for user: \(userId)")
                        self?.userId = userId
                        self?.accessToken = accessToken
                        completion(nil)
                    }
                }
            }
        }
    }

    typealias AcquireAccessTokenHandler = (AuthorizationDetails?, NSError?) -> Void

    func acquireAccessToken(username: String, password: String, completion: @escaping AcquireAccessTokenHandler) {
        let headers = ["Accept": "application/json"]

        var response = Response()
        let url = FitpayConfig.authURL + "/oauth/authorize"
        response.data = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
        if password == "fail" {
            response.json = loadDataFromJSONFile(filename: "Error")
            response.error = ErrorResponse.unhandledError(domain: MockRestClient.self)
        } else {
        response.json = loadDataFromJSONFile(filename: "getAuthorizationDetails")
        }
        let request = Request(request: url)
        request.response = response

        request.responseJSON() { (response) in

            DispatchQueue.main.async {
                if request.response?.error != nil {
                    let JSON = request.response?.json
                    var error = try? ErrorResponse(JSON)
                    if error == nil {
                        error = ErrorResponse(domain: MockRestClient.self, errorCode: request.response.data?.statusCode ?? 0 , errorMessage: request.response.error?.localizedDescription)
                    }
                    completion(nil, error)

                } else if let resultValue = request.response?.json {
                    let authorizationDetails = try? AuthorizationDetails(resultValue)
                    completion(authorizationDetails, nil)
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

extension MockRestSession {
    public enum ErrorCode: Int, Error, RawIntValue, CustomStringConvertible {
        case unknownError       = 0
        case deviceNotFound     = 10001
        case userOrDeviceEmpty  = 10002

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

    public typealias GetUserAndDeviceCompletion = (User?, DeviceInfo?, ErrorResponse?) -> Void

    class func GetUserAndDeviceWith(sessionData: SessionData, completion: @escaping GetUserAndDeviceCompletion) -> MockRestClient? {
        guard let userId = sessionData.userId, let deviceId = sessionData.deviceId else {
            completion(nil, nil, ErrorResponse(domain: RestSession.self, errorCode: RestSession.ErrorCode.userOrDeviceEmpty.rawValue, errorMessage: ""))
            return nil
        }

        let session = MockRestSession(sessionData: sessionData)
        let client = MockRestClient(session: session)

        client.user(id: userId) { (user, error) in
            guard user != nil && error == nil else {
                completion(nil, nil, error)
                return
            }

            user?.listDevices(limit: 20, offset: 0) { (devicesCollection, error) in
                guard user != nil && error == nil else {
                    completion(nil, nil, error)
                    return
                }

                if let devices = devicesCollection?.results {
                    for device in devices {
                        if device.deviceIdentifier == deviceId {
                            completion(user!, device, nil)
                            return
                        }
                    }
                }

                devicesCollection?.collectAllAvailable { (devices, error) in
                    guard error == nil, let devices = devices else {
                        completion(nil, nil, error)
                        return
                    }

                    for device in devices {
                        if device.deviceIdentifier == deviceId {
                            completion(user!, device, nil)
                            return
                        }
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


