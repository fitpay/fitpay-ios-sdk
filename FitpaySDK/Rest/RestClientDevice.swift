import Foundation
import Alamofire

extension RestClient {
    
    // MARK: - Completion Handlers
    
    /**
     Completion handler
     
     - parameter result: Provides ResultCollection<DeviceInfo> object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DevicesHandler = (_ result: ResultCollection<Device>?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter device: Provides existing DeviceInfo object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DeviceHandler = (_ device: Device?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter commits: Provides ResultCollection<Commit> object, or nil if error occurs
     - parameter error:   Provides error object, or nil if no error occurs
     */
    public typealias CommitsHandler = (_ result: ResultCollection<Commit>?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter commit:    Provides Commit object, or nil if error occurs
     - parameter error:     Provides error object, or nil if no error occurs
     */
    public typealias CommitHandler = (_ commit: Commit?, _ error: ErrorResponse?) -> Void
    
    // MARK: - Functions
    
    func createNewDevice(_ url: String, deviceInfo: Device, completion: @escaping DeviceHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }
            let params = deviceInfo.toJSON()
            
            self?.restRequest.makeRequest(url: url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let deviceInfo = try? Device(resultValue)
                deviceInfo?.client = self
                completion(deviceInfo, error)
            }
        }
    }
    
    @available(*, deprecated, message: "as of v1.2")
    func updateDevice(_ url: String, firmwareRevision: String?, softwareRevision: String?, notificationToken: String?, completion: @escaping DeviceHandler) {
        var paramsArray = [Any]()
        
        if let firmwareRevision = firmwareRevision {
            paramsArray.append(["op": "replace", "path": "/firmwareRevision", "value": firmwareRevision])
        }
        
        if let softwareRevision = softwareRevision {
            paramsArray.append(["op": "replace", "path": "/softwareRevision", "value": softwareRevision])
        }
        
        if let notificationToken = notificationToken {
            paramsArray.append(["op": "replace", "path": "/notificationToken", "value": notificationToken])
        }
        
        let params = ["params": paramsArray]
        makePatchCall(url, parameters: params, encoding: CustomJSONArrayEncoding.default, completion: completion)
    }
    
    func updateDevice(_ url: String, device: Device, completion: @escaping DeviceHandler) {
        var paramsArray = [Any]()
        
        if let firmwareRevision = device.firmwareRevision {
            paramsArray.append(["op": "replace", "path": "/firmwareRevision", "value": firmwareRevision])
        }
        
        if let softwareRevision = device.softwareRevision {
            paramsArray.append(["op": "replace", "path": "/softwareRevision", "value": softwareRevision])
        }
        
        if let notificationToken = device.notificationToken {
            paramsArray.append(["op": "replace", "path": "/notificationToken", "value": notificationToken])
        }
        
        // add more paramters when the backend supports them.
        
        let params = ["params": paramsArray]
        makePatchCall(url, parameters: params, encoding: CustomJSONArrayEncoding.default, completion: completion)
    }
    
    func getDevice(_ url: String, completion: @escaping DeviceHandler) {
        makeGetCall(url, parameters: nil, completion: completion)
    }
    
    func getDefaultCreditCard(_ url: String, completion: @escaping CreditCardHandler) {
        makeGetCall(url, parameters: nil, completion: completion)
    }
    
    func addDeviceProperty(_ url: String, propertyPath: String, propertyValue: String, completion: @escaping DeviceHandler) {
        var paramsArray = [Any]()
        paramsArray.append(["op": "add", "path": propertyPath, "value": propertyValue])
        let params = ["params": paramsArray]
        self.makePatchCall(url, parameters: params, encoding: CustomJSONArrayEncoding.default, completion: completion)
    }
    
    open func commits(_ url: String, commitsAfter: String?, limit: Int, offset: Int, completion: @escaping CommitsHandler) {
        var parameters = ["limit": "\(limit)", "offset": "\(offset)"]
        
        if commitsAfter != nil && commitsAfter!.isEmpty == false {
            parameters["commitsAfter"] = commitsAfter!
        }
        makeGetCall(url, parameters: parameters, completion: completion)
    }
    
}
