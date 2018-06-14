@testable import FitpaySDK

extension MockRestClient {

    //MARK: - Completion Handlers

    /**
     Completion handler

     - parameter result: Provides ResultCollection<DeviceInfo> object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DevicesHandler = (_ result: ResultCollection<DeviceInfo>?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter device: Provides existing DeviceInfo object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    public typealias DeviceHandler = (_ device: DeviceInfo?, _ error: ErrorResponse?) -> Void

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

    //MARK: - Functions

    func devices(_ url: String, limit: Int, offset: Int, completion: @escaping DevicesHandler) {
        let parameters = ["limit": "\(limit)", "offset": "\(offset)"]
        self.devices(url, parameters: parameters, completion: completion)
    }

    func devices(_ url: String, parameters: [String: Any]?, completion: @escaping DevicesHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "listDevices")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let deviceInfo = try? ResultCollection<DeviceInfo>(resultValue)
                deviceInfo?.client = self
                deviceInfo?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(deviceInfo, error)
            }
        }
    }

    func createNewDevice(_ url: String, deviceType: String, manufacturerName: String, deviceName: String,
                         serialNumber: String?, modelNumber: String?, hardwareRevision: String?, firmwareRevision: String?,
                         softwareRevision: String?, notificationToken: String?, systemId: String?, osName: String?,
                         secureElementId: String?, casd: String?, completion: @escaping DeviceHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }
            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "createDevice")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let deviceInfo = try? DeviceInfo(resultValue)
                deviceInfo?.client = self
                deviceInfo?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(deviceInfo, error)
            }
        }
    }

    func deleteDevice(_ url: String, completion: @escaping DeleteHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                completion(error)
            }
        }
    }

    func updateDevice(_ url: String,
                      firmwareRevision: String?,
                      softwareRevision: String?,
                      notificationToken: String?,
                      completion: @escaping DeviceHandler) {


        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "updateDevice")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let deviceInfo = try? DeviceInfo(resultValue)
                deviceInfo?.client = self
                deviceInfo?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(deviceInfo, error)
            }
        }
    }

    func addDeviceProperty(_ url: String, propertyPath: String, propertyValue: String, completion: @escaping DeviceHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "createDevice")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let deviceInfo = try? DeviceInfo(resultValue)
                deviceInfo?.client = self
                deviceInfo?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(deviceInfo, error)
            }
        }
    }

    open func commits(_ url: String, commitsAfter: String?, limit: Int, offset: Int, completion: @escaping CommitsHandler) {
        var parameters = ["limit": "\(limit)", "offset": "\(offset)"]

        if (commitsAfter != nil && commitsAfter!.isEmpty == false) {
            parameters["commitsAfter"] = commitsAfter!
        }

        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "getCommit")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let commit = try? ResultCollection<Commit>(resultValue)
                commit?.client = self
                commit?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(commit, error)
            }
        }
    }

    func commits(_ url: String, parameters: [String: Any]?,  completion: @escaping CommitsHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "getCommit")
            let request = Request(request: url)
            request.response = response

            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let commit = try? ResultCollection<Commit>(resultValue)
                commit?.client = self
                commit?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(commit, error)
            }
        }
    }

    func commit(_ url: String, completion: @escaping CommitHandler) {
        self.prepareAuthAndKeyHeaders { [weak self] (headers, error) in
            guard let headers = headers else {
                DispatchQueue.main.async {  completion(nil, error) }
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self?.loadDataFromJSONFile(filename: "getCommit")
            let request = Request(request: url)
            request.response = response
            
            self?.makeRequest(request: request) { (resultValue, error) in
                guard let strongSelf = self else { return }

                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let commit = try? Commit(resultValue)
                commit?.client = self
                commit?.applySecret(strongSelf.secret, expectedKeyId: headers[RestClient.fpKeyIdKey])
                completion(commit, error)
            }
        }
    }
}
