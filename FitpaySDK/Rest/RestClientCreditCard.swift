import Foundation
import Alamofire

extension RestClient {
    
    //MARK - Completion Handlers
    
    /**
     Completion handler
     
     - parameter result: Provides collection of credit cards, or nil if error occurs
     - parameter error:  Provides error object, or nil if no error occurs
     */
    public typealias CreditCardsHandler = (_ result: ResultCollection<CreditCard>?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter creditCard: Provides credit card object, or nil if error occurs
     - parameter error:  Provides error object, or nil if no error occurs
     */
    public typealias CreditCardHandler = (_ creditCard: CreditCard?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter pending: Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter card?:   Provides updated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error?:  Provides error object, or nil if no error occurs
     */
    public typealias CreditCardTransitionHandler = (_ pending: Bool, _ card: CreditCard?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter pending:            Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that VerificationMethod object is nil in this case
     - parameter verificationMethod: Provides VerificationMethod object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    public typealias VerifyHandler = (_ pending: Bool, _ verificationMethod: VerificationMethod?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter verificationMethods: Provides VerificationMethods objects, or nil if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    public typealias VerifyMethodsHandler = (_ verificationMethods: ResultCollection<VerificationMethod>?, _ error: ErrorResponse?) -> Void
    
    /**
     Completion handler
     
     - parameter verificationMethod: Provides VerificationMethod object, or nil if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    public typealias VerifyMethodHandler = (_ verificationMethod: VerificationMethod?, _ error: ErrorResponse?) -> Void
    
    //MARK - Internal Functions
    
    func createCreditCard(_ url: String, cardInfo: CardInfo, deviceId: String?, completion: @escaping CreditCardHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            guard let cardJSON = cardInfo.toJSONString() else {
                completion(nil, ErrorResponse(domain: RestClient.self, errorCode: nil, errorMessage: "Failed to parse JSON"))
                return
            }
            
            let jweObject = JWEObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: cardJSON, keyId: headers[RestClient.fpKeyIdKey]!)
          
            guard let encrypted = try? jweObject.encrypt(strongSelf.secret), let unwrappedEncrypted = encrypted else {
                completion(nil, ErrorResponse(domain: RestClient.self, errorCode: nil, errorMessage: "Failed to encrypt object"))
                return
            }
            
            var parameters: [String: String] =  ["encryptedData": unwrappedEncrypted]
            if let deviceId = deviceId {
                parameters["deviceId"] = deviceId
            }
                
            self?.restRequest.makeRequest(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let card = try? CreditCard(resultValue)
                card?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                card?.client = self
                completion(card, error)
            }
        }
    }
    
    func creditCards(_ url: String, excludeState: [String], limit: Int, offset: Int, deviceId: String?, completion: @escaping CreditCardsHandler) {
        var parameters: [String: Any] = ["excludeState": excludeState.joined(separator: ","), "limit": limit, "offset": offset]
        if let deviceId = deviceId {
            parameters["deviceId"] = deviceId
        }
        makeGetCall(url, parameters: parameters, completion: completion)
    }
    
    func updateCreditCard(_ url: String, name: String?, address: Address, completion: @escaping CreditCardHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let strongSelf = self else { return }
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            var operations: [[String: String]] = []
            var parameters: [String: Any] = [:]
            
            if let name = name {
                operations.append(["op": "replace", "path": "/name", "value": name])
            }
            
            if let street1 = address.street1 {
                operations.append(["op": "replace", "path": "/address/street1", "value": street1])
            }
            
            if let street2 = address.street2 {
                operations.append(["op": "replace", "path": "/address/street2", "value": street2])
            }
            
            if let city = address.city {
                operations.append(["op": "replace", "path": "/address/city", "value": city])
            }
            
            if let state = address.state {
                operations.append(["op": "replace", "path": "/address/state", "value": state])
            }
            
            if let postalCode = address.postalCode {
                operations.append(["op": "replace", "path": "/address/postalCode", "value": postalCode])
            }
            
            if let countryCode = address.countryCode {
                operations.append(["op": "replace", "path": "/address/countryCode", "value": countryCode])
            }
            
            if let updateJSON = operations.JSONString {
                let jweObject = JWEObject(JWEAlgorithm.A256GCMKW, enc: JWEEncryption.A256GCM, payload: updateJSON, keyId: headers[RestClient.fpKeyIdKey]!)
                if let encrypted = try? jweObject.encrypt(strongSelf.secret)! {
                    parameters["encryptedData"] = encrypted
                }
            }
            
            self?.restRequest.makeRequest(url: url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let card = try? CreditCard(resultValue)
                card?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                card?.client = self
                completion(card, error)
            }
        }
    }
    
    func acceptCall(_ url: String, completion: @escaping CreditCardTransitionHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(false, nil, error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    self?.handleTransitionResponse(error, completion: completion)
                    return
                }
                let card = try? CreditCard(resultValue)
                card?.client = self
                completion(false, card, nil)
            }
        }
    }

    func selectVerificationType(_ url: String, completion: @escaping VerifyHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers  else {
                DispatchQueue.main.async { completion(false, nil, error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    self?.handleVerifyResponse(error, completion: completion)
                    return
                }
                let verificationMethod = try? VerificationMethod(resultValue)
                verificationMethod?.client = self
                completion(false, verificationMethod, error)
            }
        }
    }
    
    func verify(_ url: String, verificationCode: String, completion: @escaping VerifyHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(false, nil, error) }
                return
            }
            
            let params = ["verificationCode": verificationCode]
            self?.restRequest.makeRequest(url: url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    self?.handleVerifyResponse(error, completion: completion)
                    return
                }
                let verificationMethod = try? VerificationMethod(resultValue)
                verificationMethod?.client = self
                completion(false, verificationMethod, error)
            }
        }
    }
    
    func activationCall(_ url: String, causedBy: CreditCardInitiator, reason: String, completion: @escaping CreditCardTransitionHandler) {
        prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(false, nil, error) }
                return
            }
            
            let parameters = ["causedBy": causedBy.rawValue, "reason": reason]
            self?.restRequest.makeRequest(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    self?.handleTransitionResponse(error, completion: completion)
                    return
                }
                let card = try? CreditCard(resultValue)
                card?.client = self
                completion(false, card, error)
            }
        }
    }
    
    func makeDefault(_ url: String, completion: @escaping CreditCardTransitionHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async { completion(false, nil, error) }
                return
            }
            
            self?.restRequest.makeRequest(url: url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    self?.handleTransitionResponse(error, completion: completion)
                    return
                }
                let card = try? CreditCard(resultValue)
                card?.client = self
                completion(false, card, error)
            }
        }
    }
    
    //MARK: - Private Functions
    
    private func handleVerifyResponse(_ response: ErrorResponse?, completion: @escaping VerifyHandler) {
        guard let statusCode = response?.status else {
            completion(false, nil, ErrorResponse.unhandledError(domain: RestClient.self))
            return
        }
        
        switch statusCode {
        case 202:
            completion(true, nil, nil)
        default:
            completion(false, nil, response)
        }
    }
    
    private func handleTransitionResponse(_ response: ErrorResponse?, completion: @escaping CreditCardTransitionHandler) {
        guard let statusCode = response?.status else {
            completion(false, nil, ErrorResponse.unhandledError(domain: RestClient.self))
            return
        }
        
        switch statusCode {
        case 202:
            completion(true, nil, nil)
        default:
            completion(false, nil, response)
        }
        
    }

}
