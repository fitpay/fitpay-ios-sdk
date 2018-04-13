import Foundation
import Alamofire
import AlamofireObjectMapper

extension RestClient {
    
    //MARK - Completion Handlers
    
    /**
     Completion handler
     
     - parameter relationship: Provides Relationship object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    public typealias RelationshipHandler = (_ relationship: Relationship?, _ error: NSError?) -> Void
    
    //MARK - Functions
    
    /**
     Creates a relationship between a device and a creditCard
     
     - parameter userId:       user id
     - parameter creditCardId: credit card id
     - parameter deviceId:     device id
     - parameter completion:   CreateRelationshipHandler closure
     */
    internal func createRelationship(_ url: String, creditCardId: String, deviceId: String, completion: @escaping RelationshipHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(nil, error)
                return
            }
            
            let parameters = ["creditCardId": "\(creditCardId)", "deviceId": "\(deviceId)"]
            let request = self._manager.request(url + "/relationships", method: .put, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<Relationship>) in
                DispatchQueue.main.async {
                    if response.result.error != nil {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        
                        completion(nil, error)
                    } else if let resultValue = response.result.value {
                        resultValue.client = self
                        completion(resultValue, response.result.error as NSError?)
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }
    
    internal func relationship(_ url: String, completion: @escaping RelationshipHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(nil, error)
                return
            }
            
            let request = self._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<Relationship>) in
                DispatchQueue.main.async {
                    if response.result.error != nil {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        
                        completion(nil, error)
                    } else if let resultValue = response.result.value {
                        resultValue.client = self
                        completion(resultValue, response.result.error as NSError?)
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }
    
    internal func deleteRelationship(_ url: String, completion: @escaping DeleteHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(error)
                return
            }
            
            let request = self._manager.request(url, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers)
            request.validate().responseString { (response: DataResponse<String>) in
                DispatchQueue.main.async {
                    completion(response.result.error as NSError?)
                }
            }
        }
    }
    
}
