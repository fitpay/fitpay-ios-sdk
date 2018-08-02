import Foundation
import Alamofire

public protocol RestRequestable {
    typealias RequestHandler = (_ resultValue: Any?, _ error: ErrorResponse?) -> Void

    func makeRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?, completion: @escaping RequestHandler)
}

class RestRequest: RestRequestable {
    
    lazy var manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(configuration: configuration)
    }()
    
    func makeRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters? = nil, encoding: ParameterEncoding = JSONEncoding.default, headers: HTTPHeaders? = nil, completion: @escaping RequestHandler) {
        log.verbose("API_REQUEST: url=\(url), method=\(method)")

        let request = self.manager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        request.validate(statusCode: 200..<300).responseJSON() { (response) in
            if let resultValue = response.result.value {
                completion(resultValue, nil)
                
            } else if response.response?.statusCode == 202 {
                completion(nil, nil)
                
            } else if response.result.error != nil {
                let JSON = response.data!.UTF8String
                let error = (try? ErrorResponse(JSON)) ?? ErrorResponse(domain: RestClient.self, errorCode: response.response?.statusCode ?? 0 , errorMessage: response.result.error?.localizedDescription)
                completion(nil, error)
                
            } else {
                completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
            }
        }
    }
    
}
