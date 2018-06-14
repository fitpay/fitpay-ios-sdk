
open class ResultCollection<T: Codable>: NSObject, ClientModel, Serializable, SecretApplyable {
    open var limit: Int?
    open var offset: Int?
    open var totalResults: Int?
    open var results: [T]?
    
    var links: [ResourceLink]?
    
    private let lastResourse = "last"
    private let nextResourse = "next"
    private let previousResource = "previous"

    open var nextAvailable: Bool {
        return self.links?.url(self.nextResourse) != nil
    }

    open var lastAvailable: Bool {
        return self.links?.url(self.lastResourse) != nil
    }

    open var previousAvailable: Bool {
        return self.links?.url(self.previousResource) != nil
    }

    var client: RestClientInterface? {
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
                        log.error("Failed to convert \(result) to ClientModel")
                    }
                }
            }
        }
    }
    
    private weak var _client: RestClientInterface?

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case limit
        case offset
        case totalResults
        case results
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        limit = try? container.decode(.limit)
        offset = try? container.decode(.offset)
        totalResults = try? container.decode(.totalResults)
        results = try? container.decode([T].self, forKey: .results)
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
        if let nextUrl = self.links?.url(self.nextResourse), let _ = self.results {
            self.collectAllAvailable(self.results!, nextUrl: nextUrl, completion: {
                (results, error) -> Void in
                self.results = results
                completion(self.results, error)
            })
        } else {
            log.error("Can't collect all available data, probably there is no 'next' URL.")
            completion(self.results, nil)
        }
    }

    private func collectAllAvailable(_ storage: [T], nextUrl: String, completion: @escaping CollectAllAvailableCompletion) {
        if let client = self.client {
            let _: T? = client.collectionItems(nextUrl)
            {
                (resultCollection, error) -> Void in

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

                if let nextUrlItr = resultCollection.links?.url(self.nextResourse) {
                    self.collectAllAvailable(newStorage, nextUrl: nextUrlItr, completion: completion)
                } else {
                    completion(newStorage, nil)
                }
            }
        } else {
            completion(nil, ErrorResponse.unhandledError(domain: ResultCollection.self))
        }
    }

    open func next(_ completion: @escaping RestClient.CreditCardsHandler) {
        let resource = self.nextResourse
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.creditCards(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func last(_ completion: @escaping RestClient.CreditCardsHandler) {
        let resource = self.lastResourse
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.creditCards(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func next(_ completion: @escaping RestClient.DevicesHandler) {
        let resource = self.nextResourse
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.devices(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func last(_ completion: @escaping RestClient.DevicesHandler) {
        let resource = self.lastResourse
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.devices(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func next(_ completion: @escaping RestClient.TransactionsHandler) {
        let resource = self.nextResourse
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.transactions(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func last(_ completion: @escaping RestClient.TransactionsHandler)
    {
        let resource = self.lastResourse
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.transactions(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }

    open func previous(_ completion: @escaping RestClient.CommitsHandler)
    {
        let resource = self.previousResource
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.commits(url, parameters: nil, completion: completion)
        } else {
            let error = ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
}
