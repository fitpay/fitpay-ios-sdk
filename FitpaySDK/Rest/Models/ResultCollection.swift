
open class ResultCollection<T: Codable>: NSObject, ClientModel, Serializable, SecretApplyable {
    open var limit: Int?
    open var offset: Int?
    open var totalResults: Int?
    open var results: [T]?
    
    var links: [ResourceLink]?
    
    private let lastResourceKey = "last"
    private let nextResourceKey = "next"
    private let previousResourceKey = "previous"

    open var nextAvailable: Bool {
        return self.links?.url(self.nextResourceKey) != nil
    }

    open var lastAvailable: Bool {
        return self.links?.url(self.lastResourceKey) != nil
    }

    open var previousAvailable: Bool {
        return self.links?.url(self.previousResourceKey) != nil
    }

    var client: RestClient? {
        get {
            if _client != nil {
                return _client
            }
            
            if let results = self.results {
                for result in results {
                    if let result = result as? ClientModel {
                        return result.client
                    }
                }
            }

            return nil
        }

        set {
            _client = newValue
            if let results = self.results {
                for result in results {
                    if var result = result as? ClientModel {
                        result.client = newValue
                    } else {
                        log.error("RESULT_COLLECTION: Failed to convert \(result) to ClientModel")
                    }
                }
            }
        }
    }
    
    private weak var _client: RestClient?

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case limit
        case offset
        case totalResults
        case results
        case verificationMethods
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        limit = try? container.decode(.limit)
        offset = try? container.decode(.offset)
        totalResults = try? container.decode(.totalResults)
        results = try? container.decode([T].self, forKey: .results)
        if results == nil { // hack becuase verification methods aren't strictly a result collection
            results = try? container.decode([T].self, forKey: .verificationMethods)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(limit, forKey: .limit)
        try? container.encode(offset, forKey: .offset)
        try? container.encode(totalResults, forKey: .totalResults)
    }

    func applySecret(_ secret: Data, expectedKeyId: String?) {
        if let results = self.results {
            for modelObject in results {
                if let objectWithEncryptedData = modelObject as? SecretApplyable {
                    objectWithEncryptedData.applySecret(secret, expectedKeyId: expectedKeyId)
                }
            }
        }
    }

    public typealias CollectAllAvailableCompletion = (_ results: [T]?, _ error: ErrorResponse?) -> Void

    open func collectAllAvailable(_ completion: @escaping CollectAllAvailableCompletion) {
        if let nextUrl = self.links?.url(self.nextResourceKey), let _ = self.results {
            self.collectAllAvailable(self.results!, nextUrl: nextUrl) { (results, error) -> Void in
                self.results = results
                completion(self.results, error)
            }
        } else {
            log.error("RESULT_COLLECTION: Can't collect all available data, probably there is no 'next' URL.")
            completion(self.results, nil)
        }
    }

    open func next<T>(_ completion: @escaping  (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) {
        let resource = self.nextResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeGetCall(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func last<T>(_ completion: @escaping  (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) {
        let resource = self.lastResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeGetCall(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func previous<T>(_ completion: @escaping  (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) {
        let resource = self.previousResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.makeGetCall(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    // MARK: - Private
    
    private func collectAllAvailable(_ storage: [T], nextUrl: String, completion: @escaping CollectAllAvailableCompletion) {
        guard let client = self.client else {
            completion(nil, ErrorResponse.unhandledError(domain: ResultCollection.self))
            return
        }
        
        let _: T? = client.collectionItems(nextUrl) { (resultCollection, error) -> Void in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let resultCollection = resultCollection else {
                completion(nil, ErrorResponse.unhandledError(domain: ResultCollection.self))
                return
            }
            
            let results = resultCollection.results ?? []
            let newStorage = storage + results
            
            if let nextUrlItr = resultCollection.links?.url(self.nextResourceKey) {
                self.collectAllAvailable(newStorage, nextUrl: nextUrlItr, completion: completion)
            } else {
                completion(newStorage, nil)
            }
        }
    }


}
