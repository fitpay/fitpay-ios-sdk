import Foundation
import Alamofire

extension NSError {
    
    class func error(code: Int, domain: Any, message: String) -> NSError {
        return NSError(domain: "\(domain.self)", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    class func error(code: RawIntValue & CustomStringConvertible, domain: Any, message: String? = nil) -> NSError {
        return NSError(domain: "\(domain.self)", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: message ?? code.description])
    }

    class func error<T: RawIntValue>(code: T, domain: Any, message: String) -> NSError {
        return NSError(domain: "\(domain.self)", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    class func errorWithData(code: Int, domain: Any, data: Data?, alternativeError: NSError? = nil) -> NSError {
        if let messages = data?.errorMessages, messages.count > 0 {
            return NSError(domain: "\(domain)", code: code, userInfo: [NSLocalizedDescriptionKey: messages[0]])
        } else if let message = data?.errorMessage {
            return NSError(domain: "\(domain)", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        } else if let message = data?.UTF8String {
            if message == "" {
               return NSError(domain: "\(domain)", code: code, userInfo: [NSLocalizedDescriptionKey: "UnexpectedError"])
            }
            
            return NSError(domain: "\(domain)", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }
                
        let userInfo: [AnyHashable: Any] = alternativeError?.userInfo != nil ? alternativeError!.userInfo: [NSLocalizedDescriptionKey: "Failed to parse error message"]
        return NSError(domain: "\(domain)", code: code, userInfo: userInfo as? [String: Any] )
    }
    
    class func errorWithData<T: RawIntValue>(errorCode: T, domain: AnyClass, data: Data?, alternativeError: NSError? = nil) -> NSError {
        return NSError.errorWithData(code: errorCode.rawValue, domain: domain, data: data, alternativeError: alternativeError)
    }
    
    class func errorWith<T>(dataResponse response: DataResponse<T>, domain: AnyClass) -> NSError {
        return errorWithData(code: response.response?.statusCode ?? 0, domain: domain, data: response.data, alternativeError: response.result.error as NSError?)
    }

    class func unhandledError(_ domain: Any) -> NSError {
        return NSError(domain: "\(domain)", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unhandled error"])
    }
    
    class func clientUrlError(domain: Any, code: Int, client: RestClient?, url: String?, resource: String) -> NSError? {
        if client == nil {
            return NSError.error(code: 0, domain: domain, message: "\(RestClient.self) is not set.")
        } else if url == nil {
            return NSError.error(code: 0, domain: domain, message: "Failed to retrieve url for resource '\(resource)'")
        } else {
            return nil
        }
    }
    
}
