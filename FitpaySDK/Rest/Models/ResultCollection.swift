import Foundation

open class ResultCollection<T: Codable>: NSObject, ClientModel, Serializable, SecretApplyable {
    
    open var limit: Int?
    open var offset: Int?
    open var totalResults: Int?
    open var results: [T]?
    
    open var nextAvailable: Bool {
        return links?[nextResourceKey] != nil
    }
    
    open var lastAvailable: Bool {
        return links?[lastResourceKey] != nil
    }
    
    open var previousAvailable: Bool {
        return links?[previousResourceKey] != nil
    }
    
    var links: [String: Link]?
    
    var client: RestClient? {
        get {
            if _client != nil {
                return _client
            }
            
            let resultWithClient = results?.first(where: { ($0 as? ClientModel)?.client != nil })
            return (resultWithClient as? ClientModel)?.client
        }

        set {
            _client = newValue
            results?.forEach({ ($0 as? ClientModel)?.client = newValue })
        }
    }
    
    private weak var _client: RestClient?
    
    private let lastResourceKey = "last"
    private let nextResourceKey = "next"
    private let previousResourceKey = "previous"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case limit
        case offset
        case totalResults
        case results
        case verificationMethods
    }
    
    public typealias CollectAllAvailableCompletion = (_ results: [T]?, _ error: ErrorResponse?) -> Void
    
    // MARK: - Lifecycle

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try? container.decode(.links)
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
        
        try? container.encodeIfPresent(links, forKey: .links)
        try? container.encode(limit, forKey: .limit)
        try? container.encode(offset, forKey: .offset)
        try? container.encode(totalResults, forKey: .totalResults)
    }

    func applySecret(_ secret: Data, expectedKeyId: String?) {
        results?.forEach { object in
            (object as? SecretApplyable)?.applySecret(secret, expectedKeyId: expectedKeyId)
        }
    }
    
    // MARK: - Public Functions

    open func collectAllAvailable(_ completion: @escaping CollectAllAvailableCompletion) {
        if let nextUrl = links?[nextResourceKey]?.href, results != nil {
            self.collectAllAvailable(self.results!, nextUrl: nextUrl) { (results, error) -> Void in
                self.results = results
                completion(self.results, error)
            }
        } else {
            log.warning("RESULT_COLLECTION: Can't collect all available data, probably there is no 'next' URL.")
            completion(results, nil)
        }
    }

    open func next<T>(_ completion: @escaping  (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) {
        let resource = nextResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)

    }

    open func last<T>(_ completion: @escaping  (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) {
        let resource = lastResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }

    open func previous<T>(_ completion: @escaping  (_ result: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) {
        let resource = previousResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.makeGetCall(url, parameters: nil, completion: completion)
    }

    // MARK: - Private Functions
    
    private func collectAllAvailable(_ storage: [T], nextUrl: String, completion: @escaping CollectAllAvailableCompletion) {
        guard let client = client else {
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
            
            if let nextUrlItr = resultCollection.links?[self.nextResourceKey]?.href {
                self.collectAllAvailable(newStorage, nextUrl: nextUrlItr, completion: completion)
            } else {
                completion(newStorage, nil)
            }
        }
    }
        
    private func composeError(_ resource: String) -> ErrorResponse? {
        return ErrorResponse.clientUrlError(domain: ResultCollection.self, client: client, url: links?[resource]?.href, resource: resource)
    }

}
