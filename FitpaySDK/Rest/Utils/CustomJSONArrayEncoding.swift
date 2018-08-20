import Foundation
import Alamofire

class CustomJSONArrayEncoding: ParameterEncoding {
    static var `default`: CustomJSONArrayEncoding { return CustomJSONArrayEncoding() }

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var mutableRequest = try urlRequest.asURLRequest()
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let jsonObject = parameters?["params"] {
            let jsondata = try? JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions(rawValue: 0))
            if let jsondata = jsondata {
                mutableRequest.httpBody = jsondata
            }
        }
        return mutableRequest
    }
}
