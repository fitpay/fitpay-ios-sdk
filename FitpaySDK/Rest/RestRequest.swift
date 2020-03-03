import Foundation
import Alamofire

public protocol RestRequestable {
    typealias RequestHandler = (_ resultValue: Any?, _ error: ErrorResponse?) -> Void

    func makeRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?, completion: @escaping RequestHandler)
    func makeDataRequest(url: URLConvertible, completion: @escaping RequestHandler)
}

class RestRequest: RestRequestable {
    
    lazy var manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.urlCache = nil // "Fix" for caching issue.
        
        return SessionManager(configuration: configuration)
    }()
    
    func makeRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters? = nil, encoding: ParameterEncoding = JSONEncoding.default, headers: HTTPHeaders? = nil, completion: @escaping RequestHandler) {
        log.verbose("API_REQUEST: url=\(url), method=\(method)")

        let request = manager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        request.validate(statusCode: 200..<300).responseJSON { (response) in
            if let resultValue = response.result.value {
                completion(resultValue, nil)
                
            } else if response.response?.statusCode == 202 {
                completion(nil, nil)
                
            } else if response.result.error != nil {
                let JSON = response.data!.UTF8String
                var error = try? ErrorResponse(JSON)
                if error == nil || error?.code == nil || error?.code == 0 {
                    error = ErrorResponse(domain: RestClient.self, errorCode: response.response?.statusCode ?? 0, errorMessage: response.error?.localizedDescription)
                }
                completion(nil, error)
                
            } else {
                completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
            }
        }
    }
    
    func makeDataRequest(url: URLConvertible, completion: @escaping RequestHandler) {
        log.verbose("API_REQUEST: request data url=\(url)")
        
        let request = manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
        request.validate(statusCode: 200..<300).response { (response) in
            if let resultValue = response.data {
                completion(resultValue, nil)
                
            } else if response.response?.statusCode == 202 {
                completion(nil, nil)
                
            } else if response.error != nil {
                let JSON = response.data!.UTF8String
                var error = try? ErrorResponse(JSON)
                if error == nil || error?.code == nil || error?.code == 0 {
                    error = ErrorResponse(domain: RestClient.self, errorCode: response.response?.statusCode ?? 0, errorMessage: response.error?.localizedDescription)
                }
                completion(nil, error)
                
            } else {
                completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
            }
        }
    }
    
}
