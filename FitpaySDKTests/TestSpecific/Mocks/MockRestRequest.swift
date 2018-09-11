import XCTest
import Alamofire

@testable import FitpaySDK

class MockRestRequest: RestRequestable {

    var lastParams: [String: Any]?
    var lastEncoding: ParameterEncoding?
    var lastUrl: URLConvertible?
    
    lazy var manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(configuration: configuration)
    }()
    
    func makeRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?, completion: @escaping RestRequestable.RequestHandler) {
        guard let urlString = try? url.asURL().absoluteString else {
            completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
            return
        }
        
        // create request but don't execute it so we can inspect how encoding affects the call
        let request = self.manager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                
        lastParams = parameters
        lastEncoding = encoding
        lastUrl = request.request?.url
        
        var data: Any? = nil
        
        if urlString.contains("commits") {
            data = loadDataFromJSONFile(filename: "getCommit")
            
        } else if urlString.contains("transactions") {
            data = loadDataFromJSONFile(filename: "listTransactions")
            
        } else if urlString.contains("select") {
            data = loadDataFromJSONFile(filename: "selectVerificationType")
            
        } else if urlString.contains("deactivate") {
            data = loadDataFromJSONFile(filename: "deactivateCreditCard")
            
        } else if urlString.contains("reactivate") {
            data = loadDataFromJSONFile(filename: "reactivateCreditCard")
            
        } else if urlString.contains("verify") {
            data = loadDataFromJSONFile(filename: "verified")
            
        } else if urlString.contains("acceptTerms") {
            data = loadDataFromJSONFile(filename: "acceptTermsForCreditCard")
            
        } else if urlString.contains("declineTerms") {
            data = loadDataFromJSONFile(filename: "declineTerms")
            
        }  else if urlString.contains("creditCards") && method == .post  {
            data = loadDataFromJSONFile(filename: "createCreditCard")
            
        }  else if urlString.contains("creditCards/") && method == .get {
            data = loadDataFromJSONFile(filename: "retrieveCreditCard")
            
        }  else if urlString.contains("creditCards") && method == .get {
            data = loadDataFromJSONFile(filename: "listCreditCards")
            
        } else if urlString.contains("devices") && method == .post {
            data = loadDataFromJSONFile(filename: "createDevice")
            
        } else if urlString.contains("devices") && method == .get {
            data = loadDataFromJSONFile(filename: "listDevices")
            
        } else if urlString.contains("/config/encryptionKeys") {
            data = loadDataFromJSONFile(filename: "getEncryptionKeyJson")
            
        } else if urlString.contains("users") {
            data = loadDataFromJSONFile(filename: "getUser")
            
        } else if urlString.contains("issuers") {
            data = loadDataFromJSONFile(filename: "issuers")
            
        } else if urlString.contains("/oauth/authorize") {
            data = loadDataFromJSONFile(filename: "AuthorizationDetails")
            
        } else if urlString.contains("transactions") {
            data = loadDataFromJSONFile(filename: "listTransactions")
            
        } else if urlString.contains("resetDeviceTasks") {
            data = loadDataFromJSONFile(filename: "resetDeviceTask")
            
        }
        
        if let data = data {
            completion(data, nil)
        } else {
            completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
        }
        
    }
    
    func makeDataRequest(url: URLConvertible, completion: @escaping RestRequestable.RequestHandler) {
        guard let urlString = try? url.asURL().absoluteString else {
            completion(nil, ErrorResponse.unhandledError(domain: RestClient.self))
            return
        }
        
        lastParams = nil
        lastEncoding = URLEncoding.default
        lastUrl = url
        
        if urlString.contains("assets") {
            let imagePath =  Bundle(for: type(of: self)).path(forResource: "mocImage", ofType: "png")!
            let data = UIImagePNGRepresentation(UIImage(contentsOfFile: imagePath)!)
            if let data = data {
                completion(data, nil)
            }
        }
    }
    
    private func loadDataFromJSONFile(filename: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        guard let filepath = bundle.path(forResource: filename, ofType: "json") else {
            return nil
        }
        
        let contents = try? String(contentsOfFile: filepath)
        return contents
        
    }
}
