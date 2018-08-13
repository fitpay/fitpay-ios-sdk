import Foundation
import Alamofire

extension RestClient {
    
    // MARK: - Completion Handlers
    
    /**
     Completion handler
     
     - parameter user: Provides User object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias UserHandler = (_ user: User?, _ error: ErrorResponse?) -> Void
    
    //MARK: - Public Functions
    
    /**
     Creates a new user within your organization
     
     - parameter firstName:  first name of the user
     - parameter lastName:   last name of the user
     - parameter birthDate:  birth date of the user in date format [YYYY-MM-DD]
     - parameter email:      email of the user
     - parameter completion: CreateUserHandler closure
     */
    @objc public func createUser(_ email: String, password: String, firstName: String?, lastName: String?, birthDate: String?, termsVersion: String?, termsAccepted: String?, origin: String?, originAccountCreated: String?, completion: @escaping UserHandler) {
        log.verbose("REST_CLIENT: request create user: \(email)")
        
        preparKeyHeader { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            log.verbose("REST_CLIENT: got headers: \(headers)")
            
            var parameters: [String: Any] = [:]
            if (termsVersion != nil) {
                parameters += ["termsVersion": termsVersion!]
            }
            
            if let termsVersion = termsVersion {
                parameters["termsVersion"] = termsVersion
            }
            
            if let termsAccepted = termsAccepted {
                parameters["termsAcceptedTsEpoch"] = termsAccepted
            }
            
            if let origin = origin {
                parameters["origin"] = origin
            }
            
            if let originAccountCreated = originAccountCreated {
                parameters["originAccountCreatedTsEpoch"] = originAccountCreated
            }
            
            parameters["client_id"] = FitpayConfig.clientId
            
            var rawUserInfo: [String: Any] = ["email": email, "pin": password]
            
            if let firstName = firstName {
                rawUserInfo["firstName"] = firstName
            }
            
            if let lastName = lastName {
                rawUserInfo["lastName"] = lastName
            }
            
            if let birthDate = birthDate {
                rawUserInfo["birthDate"] = birthDate
            }
            
            if let userInfoJSON = rawUserInfo.JSONString,
                let jweObject = try? JWEObject(JWEAlgorithm.A256GCMKW,
                                                               enc: JWEEncryption.A256GCM,
                                                               payload: userInfoJSON,
                                                               keyId: headers[RestClient.fpKeyIdKey]!),
                let encrypted = try? jweObject.encrypt(strongSelf.secret) {
                parameters["encryptedData"] = encrypted
            }
            
            log.verbose("REST_CLIENT: user creation url: \(FitpayConfig.apiURL)/users")
            log.verbose("REST_CLIENT: Headers: \(headers)")
            log.verbose("REST_CLIENT: user creation json: \(parameters)")
            
            self?.restRequest.makeRequest(url: FitpayConfig.apiURL + "/users", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let user = try? User(resultValue)
                user?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                user?.client = self
                completion(user, error)
            }
        }
    }
    
    /**
     Retrieves the details of an existing user. You need only supply the unique user identifier that was returned upon user creation
     
     - parameter id:         user id
     - parameter completion: UserHandler closure
     */
    @objc open func user(id: String, completion: @escaping UserHandler) {
        makeGetCall(FitpayConfig.apiURL + "/users/" + id, parameters: nil, completion: completion)
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
    @objc public func updateUser(_ url: String,  firstName: String?, lastName: String?, birthDate: String?, originAccountCreated: String?, termsAccepted: String?, termsVersion: String?, completion: @escaping UserHandler) {
        prepareAuthAndKeyHeaders { (headers, error) in
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
            
            if let updateJSON = operations.JSONString,
                let jweObject = try? JWEObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: updateJSON, keyId: headers[RestClient.fpKeyIdKey]!),
                let encrypted = try? jweObject.encrypt(self.secret)! {
                parameters["encryptedData"] = encrypted
            }
            
            self.restRequest.makeRequest(url: url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { [weak self] (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let user = try? User(resultValue)
                user?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                user?.client = self
                completion(user, error)
            }
        }
        
    }
    
}
