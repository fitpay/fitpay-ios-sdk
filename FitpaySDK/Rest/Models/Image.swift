import Foundation
import ObjectMapper

open class Image: NSObject, ClientModel, Mappable, AssetRetrivable {
    internal var links: [ResourceLink]?
    open var mimeType: String?
    open var height: Int?
    open var width: Int?
    public var client: RestClient?
    fileprivate static let selfResourceKey = "self"
    
    public required init?(map: Map) {
    }
    
    open func mapping(map: Map) {
        self.links <- (map["_links"], ResourceLinkTransformType())
        self.mimeType <- map["mimeType"]
        self.height <- map["height"]
        self.width <- map["width"]
    }
    
    open func retrieveAsset(_ completion: @escaping RestClient.AssetsHandler) {
        let resource = Image.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client {
            client.assets(url, completion: completion)
        } else {
            let error = NSError.clientUrlError(domain: Image.self, code: 0, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
}

open class ImageWithOptions: Image {
    open func retrieveAssetWith(options: [ImageAssetOption] = [], completion: @escaping RestClient.AssetsHandler) {
        let resource = Image.selfResourceKey
        let url = self.links?.url(resource)
        if let url = url, let client = self.client, let urlString = updateUrlAssetWith(urlString: url, options: options) {
            print(urlString)
            client.assets(urlString, completion: completion)
        } else {
            let error = NSError.clientUrlError(domain: Image.self, code: 0, client: client, url: url, resource: resource)
            completion(nil, error)
        }
    }
    
    internal func updateUrlAssetWith(urlString: String, options: [ImageAssetOption]) -> String? {
        guard var url = URLComponents(string: urlString) else { return urlString }
        guard url.queryItems != nil else { return urlString }
        
        for option in options {
            var optionFound = false
            for (i, queryItem) in url.queryItems!.enumerated() {
                if queryItem.name == option.urlKey {
                    url.queryItems?[i].value = String(option.urlValue)
                    optionFound = true
                    break
                }
            }
            
            if !optionFound {
                url.queryItems?.append(URLQueryItem(name: option.urlKey, value: option.urlValue))
            }
        }
        
        return (try? url.asURL())?.absoluteString
    }
}

internal class ImageTransformType<T: BaseMappable>: TransformType {
    typealias Object = [T]
    typealias JSON = [[String: Any]]
    
    func transformFromJSON(_ value: Any?) -> [T]? {
        if let images = value as? [[String: Any]] {
            var list = [T]()
            
            for raw in images {
                if let image = Mapper<T>().map(JSON: raw) {
                    list.append(image)
                }
            }
            
            return list
        }
        
        return nil
    }
    
    func transformToJSON(_ value: [T]?) -> [[String: Any]]? {
        return nil
    }
}
