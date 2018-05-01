import Foundation
import Alamofire
import AlamofireObjectMapper

extension RestClient {
    
    // MARK: - Completion Handlers
    
    /**
     Completion handler
     
     - parameter ResultCollection<User>?: Provides ResultCollection<User> object, or nil if error occurs
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    public typealias ListUsersHandler = (ResultCollection<User>?, Error?) -> Void
    
    /**
     Completion handler
     
     - parameter user: Provides User object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias UserHandler = (_ user: User?, _ error: NSError?) -> Void
    
    //MARK: - Functions
    
    /**
     Returns a list of all users that belong to your organization. The customers are returned sorted by creation date, with the most recently created customers appearing first
     
     - parameter limit:      Max number of profiles per page
     - parameter offset:     Start index position for list of entities returned
     - parameter completion: ListUsersHandler closure
     */
    open func listUsers(limit: Int, offset: Int, completion: ListUsersHandler) {
        //TODO: Implement or remove this
        assertionFailure("unimplemented functionality")
    }
    
    /**
     Creates a new user within your organization
     
     - parameter firstName:  first name of the user
     - parameter lastName:   last name of the user
     - parameter birthDate:  birth date of the user in date format [YYYY-MM-DD]
     - parameter email:      email of the user
     - parameter completion: CreateUserHandler closure
     */
    open func createUser(_ email: String, password: String, firstName: String?, lastName: String?, birthDate: String?,
                         termsVersion: String?, termsAccepted: String?, origin: String?, originAccountCreated: String?,
                         clientId: String, completion: @escaping UserHandler) {
        log.verbose("request create user: \(email)")
        
        self.preparKeyHeader { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            log.verbose("got headers: \(headers)")
            var parameters: [String: Any] = [:]
            if (termsVersion != nil) {
                parameters += ["termsVersion": termsVersion!]
            }
            
            if (termsAccepted != nil) {
                parameters += ["termsAcceptedTsEpoch": termsAccepted!]
            }
            
            if (origin != nil) {
                parameters += ["origin": origin!]
            }
            
            if (termsVersion != nil) {
                parameters += ["originAccountCreatedTsEpoch": originAccountCreated!]
            }
            
            parameters["client_id"] = clientId
            
            var rawUserInfo: [String: Any] = ["email": email, "pin": password ]
            
            if (firstName != nil) {
                rawUserInfo += ["firstName": firstName!]
            }
            
            if (lastName != nil) {
                rawUserInfo += ["lastName": lastName!]
            }
            
            if (birthDate != nil) {
                rawUserInfo += ["birthDate": birthDate!]
            }
            
            if let userInfoJSON = rawUserInfo.JSONString {
                if let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW,
                                                                  enc: JWEEncryption.A256GCM,
                                                                  payload: userInfoJSON,
                                                                  keyId: headers[RestClient.fpKeyIdKey]!) {
                    if let encrypted = try? jweObject.encrypt(strongSelf.secret) {
                        parameters["encryptedData"] = encrypted
                    }
                }
            }
            
            log.verbose("user creation url: \(strongSelf._session.baseAPIURL)/users")
            log.verbose("Headers: \(headers)")
            log.verbose("user creation json: \(parameters)")
            
            let request = strongSelf._manager.request(strongSelf._session.baseAPIURL + "/users", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<User>) in
                DispatchQueue.main.async {
                    if response.result.error != nil {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        completion(nil, error)
                        
                    } else if let resultValue = response.result.value {
                        resultValue.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                        resultValue.client = self
                        completion(resultValue, nil)
                        
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
    }
    
    /**
     Retrieves the details of an existing user. You need only supply the unique user identifier that was returned upon user creation
     
     - parameter id:         user id
     - parameter completion: UserHandler closure
     */
    @objc open func user(id: String, completion: @escaping UserHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            let request = strongSelf._manager.request(strongSelf._session.baseAPIURL + "/users/" + id,
                                                      method: .get,
                                                      parameters: nil,
                                                      encoding: JSONEncoding.default,
                                                      headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { (response: DataResponse<User>) in
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
        }
    }
    
    /**
     Update the details of an existing user
     
     - parameter id:                   user id
     - parameter firstName:            first name or nil if no change is required
     - parameter lastName:             last name or nil if no change is required
     - parameter birthDate:            birth date in date format [YYYY-MM-DD] or nil if no change is required
     - parameter originAccountCreated: origin account created in date format [TODO: specify date format] or nil if no change is required
     - parameter termsAccepted:        terms accepted in date format [TODO: specify date format] or nil if no change is required
     - parameter termsVersion:         terms version formatted as [0.0.0]
     - parameter completion:           UpdateUserHandler closure
     */
    internal func updateUser(_ url: String,
                             firstName: String?,
                             lastName: String?,
                             birthDate: String?,
                             originAccountCreated: String?,
                             termsAccepted: String?,
                             termsVersion: String?,
                             completion: @escaping UserHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(nil, error)
                return
            }
            
            var operations = [Any]()
            
            if let firstName = firstName {
                operations.append(["op": "replace", "path": "/firstName", "value": firstName])
            }
            
            if let lastName = lastName {
                operations.append(["op": "replace", "path": "/lastName", "value": lastName])
            }
            
            if let birthDate = birthDate {
                operations.append(["op": "replace", "path": "/birthDate", "value": birthDate])
            }
            
            if let originAccountCreated = originAccountCreated {
                operations.append(["op": "replace", "path": "/originAccountCreatedTs", "value": originAccountCreated])
            }
            
            if let termsAccepted = termsAccepted {
                operations.append(["op": "replace", "path": "/termsAcceptedTs", "value": termsAccepted])
            }
            
            if let termsVersion = termsVersion {
                operations.append(["op": "replace", "path": "/termsVersion", "value": termsVersion])
            }
            
            var parameters = [String: Any]()
            
            if let updateJSON = operations.JSONString {
                if let jweObject = try? JWEObject.createNewObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: updateJSON, keyId: headers[RestClient.fpKeyIdKey]!) {
                    if let encrypted = try? jweObject.encrypt(self.secret)! {
                        parameters["encryptedData"] = encrypted
                    }
                }
            }
            
            let request = self._manager.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            request.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<User>) in
                
                DispatchQueue.main.async {
                    if let _ = response.result.error {
                        let error = NSError.errorWith(dataResponse: response, domain: RestClient.self)
                        completion(nil, error)
                        
                    } else if let resultValue = response.result.value {
                        resultValue.client = self
                        if let secret = self?.secret {
                            resultValue.applySecret(secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                        }
                        completion(resultValue, response.result.error as NSError?)
                        
                    } else {
                        completion(nil, NSError.unhandledError(RestClient.self))
                    }
                }
            }
        }
        
    }
    
    /**
     Delete a single user from your organization
     
     - parameter id:         user id
     - parameter completion: DeleteHandler closure
     */
    internal func deleteUser(_ url: String, completion: @escaping DeleteHandler) {
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
    
    open func user(_ url: String, completion: @escaping UserHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let request = self?._manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
            request?.validate().responseObject(queue: DispatchQueue.global()) { [weak self] (response: DataResponse<User>) in
                guard let strongSelf = self else { return }
                
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
            
        }
    }
    
}
