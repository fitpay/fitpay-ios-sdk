@testable import FitpaySDK

extension  MockRestClient {

    //MARK - Completion Handlers

    /**
     Completion handler

     - parameter relationship: Provides Relationship object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    public typealias RelationshipHandler = (_ relationship: Relationship?, _ error: ErrorResponse?) -> Void

    //MARK - Functions

    /**
     Creates a relationship between a device and a creditCard

     - parameter userId:       user id
     - parameter creditCardId: credit card id
     - parameter deviceId:     device id
     - parameter completion:   CreateRelationshipHandler closure
     */
    public func createRelationship(_ url: String, creditCardId: String, deviceId: String, completion: @escaping RelationshipHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(nil, error)
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "createRelationship")
            let request = Request(request: url)
            request.response = response

            self.makeRequest(request: request) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let relationship = try? Relationship(resultValue)
                relationship?.client = self
                completion(relationship, error)
            }
        }
    }

    func relationship(_ url: String, completion: @escaping RelationshipHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(nil, error)
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "getRelationship")
            let request = Request(request: url)
            request.response = response

            self.makeRequest(request: request) { (resultValue, error) in
                guard let resultValue = resultValue else {
                    completion(nil, error)
                    return
                }
                let relationship = try? Relationship(resultValue)
                relationship?.client = self
                completion(relationship, error)
            }
        }
    }

    func deleteRelationship(_ url: String, completion: @escaping DeleteHandler) {
        self.prepareAuthAndKeyHeaders { (headers, error) in
            guard let headers = headers else {
                completion(error)
                return
            }

            var response = Response()
            response.data = HTTPURLResponse(url: URL(string: url)! , statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
            response.json = self.loadDataFromJSONFile(filename: "")
            let request = Request(request: url)
            request.response = response

            self.makeRequest(request: request) { (resultValue, error) in
                completion(error)
            }
        }
    }

}
