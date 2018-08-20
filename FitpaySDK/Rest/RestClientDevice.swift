import Foundation
import Alamofire

extension RestClient {
    
    //MARK: - Completion Handlers
    
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
        
    func updateDevice(_ url: String,
                               firmwareRevision: String?,
                               softwareRevision: String?,
                               notificationToken: String?,
                               completion: @escaping DeviceHandler) {
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
        
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }
            
            let params = ["params": paramsArray]
            self?.restRequest.makeRequest(url: url, method: .patch, parameters: params, encoding: CustomJSONArrayEncoding.default, headers: headers) { (resultValue, error) in
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
    
    func addDeviceProperty(_ url: String, propertyPath: String, propertyValue: String, completion: @escaping DeviceHandler) {
        var paramsArray = [Any]()
        paramsArray.append(["op": "add", "path": propertyPath, "value": propertyValue])
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }
            
            let params = ["params": paramsArray]
            self?.restRequest.makeRequest(url: url, method: .patch, parameters: params, encoding: CustomJSONArrayEncoding.default, headers: headers) { (resultValue, error) in
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
    
    open func commits(_ url: String, commitsAfter: String?, limit: Int, offset: Int, completion: @escaping CommitsHandler) {
        var parameters = ["limit": "\(limit)", "offset": "\(offset)"]
        
        if (commitsAfter != nil && commitsAfter!.isEmpty == false) {
            parameters["commitsAfter"] = commitsAfter!
        }
        makeGetCall(url, parameters: parameters, completion: completion)
    }
    
}
