//
//  RestClientDevice.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 22.05.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

extension RestClient {
    
    /**
     Completion handler
     
     - parameter result: Provides ResultCollection<DeviceInfo> object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DevicesHandler = (_ result: ResultCollection<DeviceInfo>?, _ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter device: Provides created DeviceInfo object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias CreateNewDeviceHandler = (_ device: DeviceInfo?, _ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter device: Provides existing DeviceInfo object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DeviceHandler = (_ device: DeviceInfo?, _ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter device: Provides updated DeviceInfo object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias UpdateDeviceHandler = (_ device: DeviceInfo?, _ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DeleteDeviceHandler = (_ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter commits: Provides ResultCollection<Commit> object, or nil if error occurs
     - parameter error:   Provides error object, or nil if no error occurs
     */
    public typealias CommitsHandler = (_ result: ResultCollection<Commit>?, _ error: NSError?) -> Void
    
    /**
     Completion handler
     
     - parameter commit:    Provides Commit object, or nil if error occurs
     - parameter error:     Provides error object, or nil if no error occurs
     */
    public typealias CommitHandler = (_ commit: Commit?, _ error: Error?) -> Void

    
    internal func devices(_ url: String, limit: Int, offset: Int, completion: @escaping DevicesHandler)
    {
        let parameters = [
            "limit": "\(limit)",
            "offset": "\(offset)"
        ]
        
        self.devices(url, parameters: parameters as [String: AnyObject]?, completion: completion)
    }
    
    internal func devices(_ url: String, parameters: [String: AnyObject]?, completion: @escaping DevicesHandler)
    {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let request = self?._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<ResultCollection<DeviceInfo>>) in
                    guard let strongSelf = self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self
                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    
    internal func createNewDevice(_ url: String, deviceType: String, manufacturerName: String, deviceName: String,
                                  serialNumber: String, modelNumber: String, hardwareRevision: String, firmwareRevision: String,
                                  softwareRevision: String, systemId: String, osName: String, licenseKey: String, bdAddress: String,
                                  secureElementId: String, pairing: String, completion: @escaping CreateNewDeviceHandler)
    {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let params = [
                    "deviceType": deviceType,
                    "manufacturerName": manufacturerName,
                    "deviceName": deviceName,
                    "serialNumber": serialNumber,
                    "modelNumber": modelNumber,
                    "hardwareRevision": hardwareRevision,
                    "firmwareRevision": firmwareRevision,
                    "softwareRevision": softwareRevision,
                    "systemId": systemId,
                    "osName": osName,
                    "licenseKey": licenseKey,
                    "bdAddress": bdAddress,
                    "secureElement": [
                        "secureElementId": secureElementId
                    ],
                    "pairingTs": pairing
                ] as [String: Any]
                let request = self?._manager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
                request?.validate().responseObject( queue: DispatchQueue.global()) { [weak self] (response: DataResponse<DeviceInfo>) in
                    guard let strongSelf = self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)

                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self

                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }

    internal func deleteDevice(_ url: String, completion: @escaping DeleteDeviceHandler)
    {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let request = self?._manager.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers)
                request?.validate().responseString { (response: DataResponse<String>) in
                    DispatchQueue.main.async {
                        completion(response.result.error as NSError?)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    internal func updateDevice(_ url: String, firmwareRevision: String?, softwareRevision: String?, notificationToken: String?,
                               completion: @escaping UpdateDeviceHandler)
    {
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
        
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let params = ["params": paramsArray]
                let request = self?._manager.request(url, method: .patch, parameters: params, encoding: CustomJSONArrayEncoding.default, headers: headers)
                request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<DeviceInfo>) in
                    guard let strongSelf = self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if let _ = response.result.error {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self
                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    internal func addDeviceProperty(_ url: String, propertyPath: String, propertyValue: String, completion: @escaping UpdateDeviceHandler) {
        var paramsArray = [Any]()
        paramsArray.append(["op": "add", "path": propertyPath, "value": propertyValue])
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let params = ["params": paramsArray]
                let request = self?._manager.request(url, method: .patch, parameters: params, encoding: CustomJSONArrayEncoding.default, headers: headers)
                request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<DeviceInfo>) in
                    guard let strongSelf = self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self
                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    open func commits(_ url: String, commitsAfter: String?, limit: Int, offset: Int,
                      completion: @escaping CommitsHandler)
    {
        var parameters = [
            "limit": "\(limit)",
            "offset": "\(offset)"
        ]
        
        if (commitsAfter != nil && commitsAfter!.isEmpty == false) {
            parameters["commitsAfter"] = commitsAfter!
        }
        
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let request = self?._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<ResultCollection<Commit>>) in
                    guard let strongSelf = self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self
                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    internal func commits(_ url: String, parameters: [String: AnyObject]?,
                          completion: @escaping CommitsHandler)
    {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let request = self?._manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
                request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<ResultCollection<Commit>>) in
                    guard let strongSelf = self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self
                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
    
    internal func commit(_ url: String, completion: @escaping CommitHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            if let headers = headers {
                let request = self?._manager.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
                request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<Commit>) in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if response.result.error != nil {
                            let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                            
                            completion(nil, error)
                        } else if let resultValue = response.result.value {
                            resultValue.client = self
                            resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                            completion(resultValue, response.result.error as NSError?)
                        } else {
                            completion(nil, NSError.unhandledError(RestClient.self))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
}
